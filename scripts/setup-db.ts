import { initializeDatabase } from '../lib/db';

async function main() {
  console.log('Setting up database tables...');
  
  try {
    await initializeDatabase();
    console.log('Database tables created successfully!');
  } catch (error) {
    console.error('Error setting up database:', error);
    process.exit(1);
  }
}

main();
