import mikroOrmConfig from "../mikro-orm.config.js";

import { MikroORM } from "@mikro-orm/core";
import { Save } from "../models/save.model.js";
import { BaseType } from "../enums/Base.js";
import { clampShiny, shinyConfig } from "../config/GameConfig.js";

/**
 * This script is responsible for adding shiny to all main yard saves.
 * Current configurations runs once a month on the 20th at 13:00 UTC.
 *
 * To run this script on a production server (using pm2):
 * 1) cd into the server directory
 * 2) run the command:
 * `pm2 start dist/scripts/monthly-shiny.js --cron "0 13 15 * *" --name "monthly-shiny" --no-autorestart`
 */
(async () => {
  try {
    const now = new Date();
    const utcDay = now.getUTCDate();

    if (utcDay !== 15) {
      console.log(`Exiting: Current UTC day is ${utcDay}, not the 15th.`);
      return;
    }

    const shinyAmount = shinyConfig.reward;

    const orm = await MikroORM.init(mikroOrmConfig);
    const em = orm.em.fork();

    const saves = await em.find(Save, { type: BaseType.MAIN });

    console.log(`Adding ${shinyAmount} credits to each save...`);

    for (const save of saves) {
      const currentCredits = clampShiny(save.credits);
      const awardedCredits = Math.min(shinyAmount, shinyConfig.limit - currentCredits);

      save.credits = currentCredits + awardedCredits;
      save.monthly_credits += awardedCredits;
    }

    await em.flush();
    console.log(`Updated ${saves.length} save(s) with +${shinyAmount} credits`);

    await orm.close();
    process.exit(0);
  } catch (error) {
    console.error("Failed to run monthly-shiny job:", error);
    process.exit(1);
  }
})();
