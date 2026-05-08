using FluentValidation;

namespace __SERVICE_NAME__.Application.DTOs;

public sealed record CreateItemRequest(string Name, string? Description);

public sealed class CreateItemRequestValidator : AbstractValidator<CreateItemRequest>
{
    public CreateItemRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Name is required")
            .MaximumLength(200);

        RuleFor(x => x.Description)
            .MaximumLength(2000);
    }
}

public sealed record ItemDto(
    Guid Id,
    string Name,
    string? Description,
    DateTime CreatedAt,
    DateTime UpdatedAt);
