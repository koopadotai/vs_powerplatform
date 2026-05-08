using __SERVICE_NAME__.Domain;
using __SERVICE_NAME__.Infrastructure.Persistence;
using MediatR;
using Microsoft.Extensions.Logging;

namespace __SERVICE_NAME__.Application.Commands;

public sealed record CreateItemCommand(string Name, string? Description) : IRequest<Guid>;

public sealed class CreateItemCommandHandler : IRequestHandler<CreateItemCommand, Guid>
{
    private readonly AppDbContext _db;
    private readonly ILogger<CreateItemCommandHandler> _logger;

    public CreateItemCommandHandler(AppDbContext db, ILogger<CreateItemCommandHandler> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<Guid> Handle(CreateItemCommand request, CancellationToken ct)
    {
        var item = Item.Create(request.Name, request.Description);

        _db.Items.Add(item);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Created item {ItemId} with name {ItemName}", item.Id, item.Name);

        return item.Id;
    }
}
