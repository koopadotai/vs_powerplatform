using __SERVICE_NAME__.Application.DTOs;
using __SERVICE_NAME__.Application.Queries;
using FluentValidation;
using MediatR;

namespace __SERVICE_NAME__.Api.Endpoints;

public static class ItemsEndpoints
{
    public static IEndpointRouteBuilder MapItemsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/v1/items").WithTags("Items").RequireAuthorization();

        group.MapGet("/", GetAll)
             .WithName("GetItems")
             .WithSummary("List all items")
             .WithOpenApi()
             .RequireAuthorization("CanRead");

        group.MapGet("/{id:guid}", GetById)
             .WithName("GetItem")
             .WithSummary("Get an item by id")
             .WithOpenApi()
             .RequireAuthorization("CanRead");

        group.MapPost("/", Create)
             .WithName("CreateItem")
             .WithSummary("Create a new item")
             .WithOpenApi()
             .RequireAuthorization("CanWrite");

        return app;
    }

    private static async Task<IResult> GetAll(IMediator mediator, CancellationToken ct)
    {
        var result = await mediator.Send(new GetItemsQuery(), ct);
        return Results.Ok(result);
    }

    private static async Task<IResult> GetById(Guid id, IMediator mediator, CancellationToken ct)
    {
        var item = await mediator.Send(new GetItemByIdQuery(id), ct);
        return item is null
            ? Results.Problem(title: "Item not found", statusCode: StatusCodes.Status404NotFound)
            : Results.Ok(item);
    }

    private static async Task<IResult> Create(
        CreateItemRequest request,
        IValidator<CreateItemRequest> validator,
        IMediator mediator,
        CancellationToken ct)
    {
        var validation = await validator.ValidateAsync(request, ct);
        if (!validation.IsValid)
            return Results.ValidationProblem(validation.ToDictionary());

        var id = await mediator.Send(new CreateItemCommand(request.Name, request.Description), ct);
        return Results.Created($"/v1/items/{id}", new { id });
    }
}
