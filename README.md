# ffxi-droprates
A helper addon for Ashita to print out the droprates for items.

## Important Notes

This code uses the [LandSandBoat](https://github.com/LandSandBoat/server) droprate files, which are the base drop rates for all private servers.

## Setup

Download the plugin and place it in your `addons` folder. Then load the script with `/addon load droprates`. This may take a few seconds as it fetches the latest DB files from LSB.

If you play on HorizonXI, you can place this in the `HorizonXI\Game\addons` folder of where your Hoizon was installed. You can also update the 

You can also update the make this addon load automatically when launching the game by updating `HorizonXI\Game\scripts\default.txt` file. Scroll down to where it says `# Custom user plugins and addons` and add the command:

```
##########################################################################
#
# Custom user plugins and addons
# Please be sure to review our approved list: https://horizonxi.com/addons
#
#########################################################################

/addon load droprates
```

## Usage

Commands can start with either `/dr` or `/droprate`.

### Item Search

You can search for an item by using `/dr <item_name>` where `<item_name>` is the name of the item or the auto-completed version of the item. Either will work.

Example: `/dr Beehive Chip`:

![item example](https://github.com/user-attachments/assets/4f40a9df-fd3c-4b38-af2b-e66cf4ebf509)

### Mob Search

You can search for the drops of a specific mob using their name `/dr <mob_name>` where `<mob_name>` is the exact name of the monster.

Example: `/dr Wespe`

![mob name example](https://github.com/user-attachments/assets/01f58d73-077a-4e5b-b3de-70a2eb497b71)

### Zone Search

TODO
