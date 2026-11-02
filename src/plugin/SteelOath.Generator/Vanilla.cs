using Mutagen.Bethesda.Plugins;

namespace SteelOath.Generator;

/// <summary>
/// Vanilla Skyrim.esm records this mod links to. Only FormIDs are referenced;
/// no Bethesda data or assets are copied into the plugin or the repo.
/// FormIDs were looked up with the Mutagen.Bethesda.FormKeys.SkyrimSE package.
/// </summary>
internal static class Vanilla
{
    public static readonly ModKey Skyrim = ModKey.FromFileName("Skyrim.esm");
    private static FormKey K(uint id) => new(Skyrim, id);

    public static readonly FormKey PlayerRef = K(0x000014);
    public static readonly FormKey MQ101 = K(0x03372B);
    public static readonly FormKey WerewolfBeastRace = K(0x0CDD84);

    // Keywords used to recognise what the player equips
    public static readonly FormKey ArmorLight = K(0x06BBD3);
    public static readonly FormKey ArmorShield = K(0x0965B2);
    public static readonly FormKey WeapTypeBow = K(0x01E715);

    // Equip slots
    public static readonly FormKey EquipVoice = K(0x025BEE);
    public static readonly FormKey EquipEitherHand = K(0x013F44);

    // Hold locations and crime factions, in the script's HoldName order.
    public static readonly FormKey[] HoldLocations =
    {
        K(0x016772), K(0x01676A), K(0x01676C), K(0x016770), K(0x016769),
        K(0x01676D), K(0x01676F), K(0x01676E), K(0x01676B),
    };
    public static readonly FormKey[] CrimeFactions =
    {
        K(0x0267EA), K(0x0267E3), K(0x02816B), K(0x029DB0), K(0x02816C),
        K(0x02816E), K(0x028170), K(0x02816D), K(0x02816F),
    };
    public static readonly FormKey ClothingNecklace = K(0x10CD0A);
    public static readonly FormKey VendorItemJewelry = K(0x08F95A);
    public static readonly FormKey DefaultRace = K(0x000019);
    public static readonly FormKey GoldAmuletAA = K(0x091722);
    public static readonly FormKey SOMMono01400 = K(0x05A28A);
    public static readonly FormKey AudioCategorySFX = K(0x0172A1);
    public const string GoldAmuletGroundModel = @"Clothes\AmuletsandRings\GoldAmuletGND.nif";
}
