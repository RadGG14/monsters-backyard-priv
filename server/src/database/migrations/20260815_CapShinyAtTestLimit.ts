import { Migration } from "@mikro-orm/migrations";

/**
 * Caps existing balances before enforcing the test-game shiny limit at the
 * database layer. This prevents older saves from bypassing the runtime cap.
 */
export class CapShinyAtTestLimit extends Migration {
  async up(): Promise<void> {
    this.addSql(`
      UPDATE "bym"."save"
      SET "credits" = 9999999
      WHERE "credits" > 9999999;

      ALTER TABLE "bym"."save"
        ADD CONSTRAINT "save_credits_max_check"
        CHECK ("credits" <= 9999999);
    `);
  }

  async down(): Promise<void> {
    this.addSql(`
      ALTER TABLE "bym"."save"
        DROP CONSTRAINT IF EXISTS "save_credits_max_check";
    `);
  }
}
