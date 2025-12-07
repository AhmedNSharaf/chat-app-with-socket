/**
 * DELETE ALL USERS - Administrative Script
 *
 * WARNING: This script deletes ALL data from the database!
 * - All users
 * - All messages
 * - All groups
 * - All group messages
 *
 * USE WITH EXTREME CAUTION!
 */

const mongoose = require('mongoose');
require('dotenv').config();

const User = require('./models/User');
const Message = require('./models/Message');
const Group = require('./models/Group');
const GroupMessage = require('./models/GroupMessage');

async function deleteAllData() {
  try {
    // Connect to MongoDB
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/chat-app');
    console.log('✅ Connected to MongoDB\n');

    // Delete all data
    console.log('🗑️  Starting deletion process...\n');

    const userResult = await User.deleteMany({});
    console.log(`   ✓ Users deleted: ${userResult.deletedCount}`);

    const messageResult = await Message.deleteMany({});
    console.log(`   ✓ Messages deleted: ${messageResult.deletedCount}`);

    const groupResult = await Group.deleteMany({});
    console.log(`   ✓ Groups deleted: ${groupResult.deletedCount}`);

    const groupMessageResult = await GroupMessage.deleteMany({});
    console.log(`   ✓ Group Messages deleted: ${groupMessageResult.deletedCount}`);

    console.log('\n✅ ALL DATA DELETED SUCCESSFULLY!\n');
    console.log('Summary:');
    console.log(`   - Users: ${userResult.deletedCount}`);
    console.log(`   - Messages: ${messageResult.deletedCount}`);
    console.log(`   - Groups: ${groupResult.deletedCount}`);
    console.log(`   - Group Messages: ${groupMessageResult.deletedCount}`);
    console.log(`   - Total: ${userResult.deletedCount + messageResult.deletedCount + groupResult.deletedCount + groupMessageResult.deletedCount} records\n`);

    // Close connection
    await mongoose.connection.close();
    console.log('🔌 Disconnected from MongoDB');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error deleting data:', error);
    process.exit(1);
  }
}

// Confirm before deletion
console.log('⚠️  WARNING: This will delete ALL data from the database!');
console.log('⚠️  This action CANNOT be undone!\n');

// Run deletion
deleteAllData();
