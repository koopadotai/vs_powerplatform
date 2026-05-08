using __SERVICE_NAME__.Domain;
using FluentAssertions;
using Xunit;

namespace __SERVICE_NAME__.Tests.Unit;

public sealed class ItemTests
{
    [Fact]
    public void Create_WithValidName_ReturnsItem()
    {
        var item = Item.Create("Laptop", "MacBook Pro 16");

        item.Id.Should().NotBe(Guid.Empty);
        item.Name.Should().Be("Laptop");
        item.Description.Should().Be("MacBook Pro 16");
        item.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(2));
    }

    [Fact]
    public void Create_WithEmptyName_Throws()
    {
        var act = () => Item.Create("", null);
        act.Should().Throw<ArgumentException>().WithMessage("*Name*");
    }

    [Fact]
    public void Create_TrimsWhitespace()
    {
        var item = Item.Create("  Laptop  ", "  Spec  ");

        item.Name.Should().Be("Laptop");
        item.Description.Should().Be("Spec");
    }

    [Fact]
    public void Rename_UpdatesNameAndTimestamp()
    {
        var item = Item.Create("Old", null);
        var originalUpdate = item.UpdatedAt;

        Thread.Sleep(10);
        item.Rename("New");

        item.Name.Should().Be("New");
        item.UpdatedAt.Should().BeAfter(originalUpdate);
    }
}
