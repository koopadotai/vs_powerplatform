using __SERVICE_NAME__.Api.Endpoints;
using __SERVICE_NAME__.Application;
using __SERVICE_NAME__.Infrastructure;
using __SERVICE_NAME__.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// ── Logging ──────────────────────────────────────────────────────
builder.Host.UseSerilog((ctx, config) => config
    .ReadFrom.Configuration(ctx.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console());

// ── Configuration / Key Vault ────────────────────────────────────
var keyVaultUri = builder.Configuration["KeyVault:Uri"];
if (!string.IsNullOrWhiteSpace(keyVaultUri) && !builder.Environment.IsDevelopment())
{
    builder.Configuration.AddAzureKeyVault(new Uri(keyVaultUri), new Azure.Identity.DefaultAzureCredential());
}

// ── Services ────────────────────────────────────────────────────
builder.Services.AddProblemDetails();
builder.Services.AddOpenApi();
builder.Services.AddEndpointsApiExplorer();

// AuthN
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => builder.Configuration.Bind("Jwt", options));

// AuthZ
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("CanRead", p => p.RequireAuthenticatedUser());
    options.AddPolicy("CanWrite", p => p.RequireAuthenticatedUser().RequireClaim("scope", "items.write"));
});

// Persistence
builder.Services.AddDbContext<AppDbContext>(opts =>
    opts.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

// Application services
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

// API versioning
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new Asp.Versioning.ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
});

// Observability
builder.Services.AddOpenTelemetry()
    .ConfigureResource(r => r.AddService("__SERVICE_NAME__"))
    .WithTracing(t => t
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddConsoleExporter());

// Health
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>("database");

var app = builder.Build();

// ── Middleware ──────────────────────────────────────────────────
app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseHttpsRedirection();
app.UseSerilogRequestLogging();
app.UseAuthentication();
app.UseAuthorization();

// ── OpenAPI (dev) ───────────────────────────────────────────────
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// ── Required endpoints ──────────────────────────────────────────
app.MapGet("/health", () => Results.Ok(new { status = "live" })).AllowAnonymous();
app.MapHealthChecks("/ready").AllowAnonymous();
app.MapGet("/version", () => Results.Ok(new
{
    name = "__SERVICE_NAME__",
    version = typeof(Program).Assembly.GetName().Version?.ToString() ?? "1.0.0",
    builtAt = File.GetLastWriteTimeUtc(typeof(Program).Assembly.Location).ToString("o")
})).AllowAnonymous();

// ── Domain endpoints ────────────────────────────────────────────
app.MapItemsEndpoints();

app.Run();

public partial class Program { }
