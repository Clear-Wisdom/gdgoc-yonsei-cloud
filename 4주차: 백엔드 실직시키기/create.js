const { Firestore, FieldValue } = require("@google-cloud/firestore");

const firestore = new Firestore({ databaseId: 'test-database' });
const COLLECTION_NAME = "commentApp";
const DOCUMENT_ID = "arS5HKzyajR0p1fVPbFj";

const commentsCollection = () =>
    firestore
        .collection(COLLECTION_NAME)
        .doc(DOCUMENT_ID)
        .collection("comments");

const customAllowedOrigins = (process.env.ALLOWED_ORIGINS || "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);

const allowedOrigins = [
    ...new Set([
        "https://storage.googleapis.com", // The origin for the frontend
        ...customAllowedOrigins,
    ]),
];

const getAllowedOrigin = (origin) => {
    if (allowedOrigins.length === 0 || allowedOrigins.includes("*")) {
        return "*";
    }
    if (origin && allowedOrigins.includes(origin)) {
        return origin;
    }
    return allowedOrigins[0];
};

const toSerializableComment = (doc) => {
    const data = doc.data() || {};
    const createdAt = data.createdAt;
    return {
        id: data.id || doc.id,
        content: data.content || "",
        createdAt: createdAt ? createdAt.toDate().toISOString() : null,
    };
};

exports.create = async (req, res) => {
    const origin = getAllowedOrigin(req.get("Origin"));
    res.set("Access-Control-Allow-Origin", origin);
    res.set(
        "Access-Control-Allow-Methods",
        "GET, POST, PUT, PATCH, DELETE, OPTIONS"
    );
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.set("Access-Control-Max-Age", "3600");

    if (req.method === "OPTIONS") {
        return res.status(204).send("");
    }

    if (req.method !== "POST") {
        return res.status(405).json({ error: "Method Not Allowed. Use POST." });
    }

    try {
        const content =
            req.body && typeof req.body.content === "string"
                ? req.body.content.trim()
                : "";

        if (!content) {
            return res.status(400).json({ error: "content is required." });
        }

        const docRef = commentsCollection().doc();

        await firestore
            .collection(COLLECTION_NAME)
            .doc(DOCUMENT_ID)
            .set(
                { lastCreatedAt: FieldValue.serverTimestamp() },
                { merge: true }
            );

        await docRef.set({
            id: docRef.id,
            content,
            createdAt: FieldValue.serverTimestamp(),
        });

        const savedSnapshot = await docRef.get();
        const comment = toSerializableComment(savedSnapshot);

        return res.status(201).json({ comment });
    } catch (error) {
        console.error("Create comment failed:", error);
        return res.status(500).json({ error: "Failed to create comment." });
    }
};
