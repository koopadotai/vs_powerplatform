using __SERVICE_NAME__.Application.DTOs;
using __SERVICE_NAME__.Infrastructure.Persistence;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace __SERVICE_NAME__.Application.Queries;

public sealed record GetItemsQuery() : IRequest<IReadOnlyList<ItemDto>>;

public sealed class GetItemsQueryHandler : IRequestHandler<GetItemsQuery, IReadOnlyList<ItemDto>>
{
    private readonly AppDbContext _db;

    public GetItemsQueryHandler(AppDbContext db) => _db = db;

    public async Task<IReadOnlyList<ItemDto>> Handle(GetItemsQuery request, CancellationToken ct)
    {
        return await _db.Items
            .OrderByDescending(i => i.CreatedAt)
            .Select(i => new ItemDto(i.Id, i.Name, i.Description, i.CreatedAt, i.UpdatedAt))
            .ToListAsync(ct);
    }
}

public sealed record GetItemByIdQuery(Guid Id) : IRequest<ItemDto?>;

public sealed class GetItemByIdQueryHandler : IRequestHandler<GetItemByIdQuery, ItemDto?>
{
    private readonly AppDbContext _db;

    public GetItemByIdQueryHandler(AppDbContext db) => _db = db;

    public async Task<ItemDto?> Handle(GetItemByIdQuery request, CancellationToken ct)
    {
        return await _db.Items
            .Where(i => i.Id == request.Id)
            .Select(i => new ItemDto(i.Id, i.Name, i.Description, i.CreatedAt, i.UpdatedAt))
            .FirstOrDefaultAsync(ct);
    }
}
