import { getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const localItineraries = new Map();

function getUserItineraries(uid) {
  if (getApps().length === 0) return null;
  return getFirestore().collection('users').doc(uid).collection('itineraries');
}

export async function listItineraries(uid) {
  const collection = getUserItineraries(uid);
  if (!collection) {
    return Array.from(localItineraries.values())
      .filter((itinerary) => itinerary.userId === uid)
      .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
  }

  const snapshot = await collection.get();
  return snapshot.docs
    .map((doc) => doc.data())
    .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
}

export async function getItinerary(uid, id) {
  const collection = getUserItineraries(uid);
  if (!collection) {
    return localItineraries.get(`${uid}/${id}`) ?? null;
  }

  const snapshot = await collection.doc(id).get();
  return snapshot.exists ? snapshot.data() : null;
}

export async function saveItinerary(uid, itinerary) {
  const collection = getUserItineraries(uid);
  if (!collection) {
    localItineraries.set(`${uid}/${itinerary.id}`, itinerary);
    return;
  }

  await collection.doc(itinerary.id).set(itinerary, { merge: true });
}

export async function deleteItinerary(uid, id) {
  const collection = getUserItineraries(uid);
  if (!collection) {
    return localItineraries.delete(`${uid}/${id}`);
  }

  const reference = collection.doc(id);
  const snapshot = await reference.get();
  if (!snapshot.exists) return false;
  await reference.delete();
  return true;
}

export async function findItineraryByShareCode(shareCode) {
  if (getApps().length === 0) {
    return Array.from(localItineraries.values())
      .find((itinerary) => itinerary.shareCode === shareCode) ?? null;
  }

  const snapshot = await getFirestore()
    .collectionGroup('itineraries')
    .where('shareCode', '==', shareCode)
    .limit(1)
    .get();
  return snapshot.empty ? null : snapshot.docs[0].data();
}
