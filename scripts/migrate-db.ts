import { config } from 'dotenv';
config({ path: '.env.local' });

import { runMigrations } from '../lib/migrations';

async function main() {
  console.log('Running database migrations...');

  try {
    const appliedMigrations = await runMigrations();

    if (appliedMigrations.length == 0) {
      console.log('No pending migrations.');
      return;
    }

    console.log(`Applied migrations: ${appliedMigrations.join(', ')}`);
  } catch (error) {
    console.error('Error running database migrations:', error);
    process.exit(1);
  }
}

main();
