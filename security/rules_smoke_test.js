const path = require('path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc } = require('firebase/firestore');

(async () => {
  const root = path.resolve(__dirname, '..');
  const testEnv = await initializeTestEnvironment({
    projectId: process.env.FIREBASE_PROJECT_ID || 'fit-mall-rules-test',
    firestore: { rules: require('fs').readFileSync(path.join(root, 'firestore.rules'), 'utf8') },
  });

  try {
    const guest = testEnv.unauthenticatedContext();
    const user = testEnv.authenticatedContext('user-a', { email: 'user-a@example.com' });
    const otherUser = testEnv.authenticatedContext('user-b', { email: 'user-b@example.com' });

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'orders', 'order-a'), { userId: 'user-a', status: 'pending' });
    });
    await assertSucceeds(getDoc(doc(guest.firestore(), 'products', 'product-a')));
    await assertFails(getDoc(doc(guest.firestore(), 'admin_notifications', 'notice-a')));
    await assertFails(setDoc(doc(user.firestore(), 'products', 'product-a'), { name: 'blocked' }));
    await assertSucceeds(setDoc(doc(user.firestore(), 'restock_alerts', 'alert-a'), {
      userId: 'user-a',
      productId: 'product-a',
    }));
    await assertSucceeds(getDoc(doc(user.firestore(), 'orders', 'order-a')));
    await assertFails(getDoc(doc(otherUser.firestore(), 'orders', 'order-a')));

    console.log('Rules smoke test passed');
  } finally {
    await testEnv.cleanup();
  }
})().catch((error) => {
  console.error('Rules smoke test failed:', error.stack || error.code || error.message);
  process.exitCode = 1;
});
