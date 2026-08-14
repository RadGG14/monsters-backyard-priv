import { Save } from "../../models/save.model.js";
import { logger } from "../../utils/logger.js";
import { type StoreItem, storeItems } from "../../game-data/store/storeItems.js";
import { purchaseKeys, rewardCredits } from "../../game-data/store/purchaseKeys.js";
import { User } from "../../models/user.model.js";
import type { Context } from "koa";
import { clampShiny, shinyConfig } from "../../config/GameConfig.js";

interface Mushrooms {
  MUSHROOM1: number;
  MUSHROOM2: number;
  MUSHROOM3: number;
}

const hasCollectedReward = (save: Save, item: string, quantity: number) =>
  (save.storedata?.[item]?.q ?? 0) > quantity;

const grantShiny = (save: Save, amount: number) => {
  save.credits = clampShiny(save.credits + amount);
};

/**
 *  Keeps track of shiny (credits) spent and obtained.
 * @param {Save} save - The object representing the user's save data.
 * @param {string} item - The item identifier for which credits are spent or obtained.
 * @param {number} quantity - The quantity of the item affecting credit changes.
 */
export const updateCredits = (ctx: Context, save: Save, item: string, quantity: number) => {
  const user: User = ctx.authUser;
  const userSave = user.save!;

  if (quantity <= 0) {
    logger.error("Invalid purchase quantity!", { item, quantity });
    return;
  }

  // Handle mushrooms
  const mushroomCredits: Mushrooms = {
    MUSHROOM1: shinyConfig.mushroom.regular,
    MUSHROOM2: shinyConfig.mushroom.bonus,
    MUSHROOM3: shinyConfig.mushroom.regular,
  };
  if (item in mushroomCredits) {
    grantShiny(userSave, mushroomCredits[item as keyof Mushrooms]);
    return;
  }

  // Handle special quest rewards that grant the higher test reward.
  if (item in rewardCredits) {
    const collected = hasCollectedReward(save, item, quantity);

    if (!collected) grantShiny(userSave, rewardCredits[item]);
    return;
  }

  // Handle purchases not in the store
  if (purchaseKeys.has(item)) {
    userSave.credits = clampShiny(userSave.credits - quantity);
    return;
  }

  // Every regular quest pays the shared test quest reward. The client sends
  // quest IDs with a Q prefix and the purchase count prevents repeat claims.
  if (item.startsWith("Q")) {
    const collected = hasCollectedReward(save, item, quantity);

    if (!collected) grantShiny(userSave, shinyConfig.quest);
    return;
  }

  // Handle store purchases
  const storeItem: StoreItem = storeItems[item];

  if (!storeItem?.c) {
    logger.error(`Not a store item! Add to non-store items list ${item}`);
    return;
  }

  let itemCost: number = storeItem.c[0];

  if (storeItem.c.length > 1) {
    // The item has a scaling cost depending on how many of that item the player currently owns
    // We subtract 1 here since the item would've been already added to the player's save by the caller
    const currentQuantity: number = save.storedata?.[item].q - 1;
    itemCost = storeItem.c[currentQuantity];
  }

  userSave.credits = clampShiny(userSave.credits - itemCost * quantity);
};
