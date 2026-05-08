using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace __SERVICE_NAME__.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
    {
        // Register external integrations (Dataverse client, HTTP clients, etc.) here.
        // Example:
        // services.AddSingleton(sp =>
        // {
        //     var connStr = config.GetConnectionString("Dataverse")
        //         ?? throw new InvalidOperationException("Dataverse connection string missing");
        //     return new ServiceClient(connStr);
        // });

        return services;
    }
}
