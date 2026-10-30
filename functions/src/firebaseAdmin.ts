import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, type Firestore} from "firebase-admin/firestore";
import {onInit} from "firebase-functions/v2/core";
import {setGlobalOptions} from "firebase-functions/v2/options";

// Vale para todas as funções (este módulo é importado antes delas).
setGlobalOptions({maxInstances: 10});

/**
 * Com `EXIGIR_APP_CHECK=true` no functions/.env, as funções só aceitam
 * chamadas do app de verdade (Play Integrity / App Attest). Fica desligado
 * até o App Check estar configurado no console, senão o app para de jogar.
 */
export const EXIGIR_APP_CHECK = process.env.EXIGIR_APP_CHECK === "true";

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
