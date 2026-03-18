import { config } from 'dotenv';
config({ path: '.env.local' });

import { initializeDatabase } from '../lib/db';
import { runMigrations } from '../lib/migrations';

async function main() {
  console.log('Setting up database tables...');
  
  try {
    await initializeDatabase();
    const appliedMigrations = await runMigrations();
    if (appliedMigrations.length > 0) {
      console.log(`Applied migrations: ${appliedMigrations.join(', ')}`);
    }
    console.log('Database tables created successfully!');
  } catch (error) {
    console.error('Error setting up database:', error);
    process.exit(1);
  }
}

main();
