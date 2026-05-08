using __SERVICE_NAME__.Domain;
using Microsoft.EntityFrameworkCore;

namespace __SERVICE_NAME__.Infrastructure.Persistence;

public sealed class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Item> Items => Set<Item>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        builder.Entity<Item>(e =>
        {
            e.ToTable("Items");
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).IsRequired().HasMaxLength(200);
            e.Property(x => x.Description).HasMaxLength(2000);
            e.Property(x => x.CreatedAt).IsRequired();
            e.Property(x => x.UpdatedAt).IsRequired();

            e.HasIndex(x => x.Name);
        });

        base.OnModelCreating(builder);
    }
}
