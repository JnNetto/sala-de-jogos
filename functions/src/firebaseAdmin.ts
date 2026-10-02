import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, type Firestore} from "firebase-admin/firestore";
import {onInit} from "firebase-functions/v2/core";

let firestore: Firestore | undefined;

function ensureDb(): Firestore {
  if (!firestore) {
    if (getApps().length === 0) {
      initializeApp();
    }
    firestore = getFirestore();
  }
  return firestore;
}

onInit(() => {
  ensureDb();
});

export const db = new Proxy({} as Firestore, {
  get(_target, property, receiver) {
    const real = ensureDb();
    const value = Reflect.get(real, property, receiver);
    return typeof value === "function" ? value.bind(real) : value;
  },
});
