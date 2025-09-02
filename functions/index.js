const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
require("dotenv").config();

// Initialize Firebase Admin
admin.initializeApp();

// Google Places API configuration from environment variables
const GOOGLE_PLACES_API_KEY = process.env.GOOGLE_PLACES_API_KEY;
const PLACES_BASE_URL = "https://places.googleapis.com/v1";

if (!GOOGLE_PLACES_API_KEY) {
    throw new Error("GOOGLE_PLACES_API_KEY environment variable is required");
}

/**
 * Search for destinations using Google Places API
 */
exports.searchDestinations = onCall(async (request) => {
    try {
        const { input } = request.data;

        if (!input || typeof input !== "string") {
            throw new Error("Input is required");
        }

        logger.info(`🔍 Searching destinations for: ${input}`);

        // Step 1: Get autocomplete suggestions
        const autocompleteResponse = await fetch(`${PLACES_BASE_URL}/places:autocomplete`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
                "X-Goog-FieldMask": "suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat",
            },
            body: JSON.stringify({
                input: input,
                includedPrimaryTypes: ["locality", "country", "administrative_area_level_1"],
            }),
        });

        if (!autocompleteResponse.ok) {
            throw new Error(`Autocomplete failed: ${autocompleteResponse.status}`);
        }

        const autocompleteData = await autocompleteResponse.json();
        const suggestions = autocompleteData.suggestions || [];

        // Step 2: Get place details for each suggestion
        const places = [];
        const seen = new Set();

        for (const suggestion of suggestions) {
            const prediction = suggestion.placePrediction;
            if (!prediction || !prediction.placeId) continue;

            const placeId = prediction.placeId;
            if (seen.has(placeId)) continue;
            seen.add(placeId);

            try {
                const detailsResponse = await fetch(`${PLACES_BASE_URL}/places/${placeId}`, {
                    headers: {
                        "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
                        "X-Goog-FieldMask": "id,displayName,formattedAddress,location,rating,userRatingCount,types,photos",
                    },
                });

                if (detailsResponse.ok) {
                    const placeDetails = await detailsResponse.json();

                    // Fetch photos for this place
                    try {
                        const photosResponse = await fetch(`${PLACES_BASE_URL}/places/${placeId}`, {
                            headers: {
                                "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
                                "X-Goog-FieldMask": "photos",
                            },
                        });

                        if (photosResponse.ok) {
                            const photosData = await photosResponse.json();
                            const photos = photosData.photos || [];

                            // Convert photo names to URLs (limit to 3 for search results)
                            const photoUrls = [];
                            for (let i = 0; i < photos.length && i < 3; i++) {
                                const photoName = photos[i].name;
                                if (photoName) {
                                    const photoUrl = `${PLACES_BASE_URL}/${photoName}/media?maxWidthPx=200&key=${GOOGLE_PLACES_API_KEY}`;
                                    photoUrls.push(photoUrl);
                                }
                            }

                            // Add photo URLs to place details
                            placeDetails.photoUrls = photoUrls;
                        }
                    } catch (photoError) {
                        logger.warn(`Failed to get photos for ${placeId}:`, photoError);
                        placeDetails.photoUrls = [];
                    }

                    places.push(placeDetails);
                }
            } catch (error) {
                logger.warn(`Failed to get details for place ${placeId}:`, error);
            }
        }

        logger.info(`✅ Found ${places.length} destinations`);
        return { places };
    } catch (error) {
        logger.error("❌ Error in searchDestinations:", error);
        throw new Error(`Search destinations failed: ${error.message}`);
    }
});

/**
 * Get place photos using Google Places API
 */
exports.getPlacePhotos = onCall(async (request) => {
    try {
        const { placeId, maxPhotos = 20, maxWidth = 800 } = request.data;

        if (!placeId) {
            throw new Error("Place ID is required");
        }

        logger.info(`📸 Getting photos for place: ${placeId}`);

        // Get place photos
        const photosResponse = await fetch(`${PLACES_BASE_URL}/places/${placeId}`, {
            headers: {
                "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
                "X-Goog-FieldMask": "photos",
            },
        });

        if (!photosResponse.ok) {
            throw new Error(`Photos request failed: ${photosResponse.status}`);
        }

        const photosData = await photosResponse.json();
        const photos = photosData.photos || [];

        logger.info(`📸 API returned ${photos.length} photos`);

        // Convert photo names to URLs
        const photoUrls = [];
        for (let i = 0; i < photos.length && i < maxPhotos; i++) {
            const photoName = photos[i].name;
            if (photoName) {
                const photoUrl = `${PLACES_BASE_URL}/${photoName}/media?maxWidthPx=${maxWidth}&key=${GOOGLE_PLACES_API_KEY}`;
                photoUrls.push(photoUrl);
            }
        }

        // If we need more photos, try nearby search
        if (photoUrls.length < maxPhotos) {
            logger.info(`📸 Only ${photoUrls.length} photos found, searching nearby...`);

            try {
                // Get main place location first
                const placeResponse = await fetch(`${PLACES_BASE_URL}/places/${placeId}`, {
                    headers: {
                        "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
                        "X-Goog-FieldMask": "location",
                    },
                });

                if (placeResponse.ok) {
                    const placeData = await placeResponse.json();
                    const location = placeData.location;

                    if (location) {
                        // Search nearby tourist attractions
                        const nearbyResponse = await fetch(`${PLACES_BASE_URL}/places:searchNearby`, {
                            method: "POST",
                            headers: {
                                "Content-Type": "application/json",
                                "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
                                "X-Goog-FieldMask": "places.photos",
                            },
                            body: JSON.stringify({
                                locationRestriction: {
                                    circle: {
                                        center: {
                                            latitude: location.latitude,
                                            longitude: location.longitude,
                                        },
                                        radius: 1000.0,
                                    },
                                },
                                includedTypes: ["tourist_attraction"],
                                maxResultCount: 5,
                            }),
                        });

                        if (nearbyResponse.ok) {
                            const nearbyData = await nearbyResponse.json();
                            const nearbyPlaces = nearbyData.places || [];

                            for (const place of nearbyPlaces) {
                                const placePhotos = place.photos || [];
                                for (const photo of placePhotos) {
                                    if (photoUrls.length >= maxPhotos) break;

                                    const photoName = photo.name;
                                    if (photoName) {
                                        const photoUrl = `${PLACES_BASE_URL}/${photoName}/media?maxWidthPx=${maxWidth}&key=${GOOGLE_PLACES_API_KEY}`;
                                        photoUrls.push(photoUrl);
                                    }
                                }
                                if (photoUrls.length >= maxPhotos) break;
                            }
                        }
                    }
                }
            } catch (nearbyError) {
                logger.warn("Error getting nearby photos:", nearbyError);
            }
        }

        logger.info(`✅ Returning ${photoUrls.length} photo URLs`);
        return { photos: photoUrls };
    } catch (error) {
        logger.error("❌ Error in getPlacePhotos:", error);
        throw new Error(`Get place photos failed: ${error.message}`);
    }
});

/**
 * Get place details by ID
 */
exports.getPlaceDetails = onCall(async (request) => {
    try {
        const { placeId } = request.data;

        if (!placeId) {
            throw new Error("Place ID is required");
        }

        logger.info(`📍 Getting place details for: ${placeId}`);

        const response = await fetch(`${PLACES_BASE_URL}/places/${placeId}`, {
            headers: {
                "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
                "X-Goog-FieldMask": "id,displayName,formattedAddress,location,rating,userRatingCount,types,photos",
            },
        });

        if (!response.ok) {
            throw new Error(`Place details request failed: ${response.status}`);
        }

        const placeData = await response.json();
        const placeName = placeData.displayName && placeData.displayName.text ? placeData.displayName.text : "Unknown";
        logger.info(`✅ Place details retrieved: ${placeName}`);

        return { place: placeData };
    } catch (error) {
        logger.error("❌ Error in getPlaceDetails:", error);
        throw new Error(`Get place details failed: ${error.message}`);
    }
});

/**
 * Get autocomplete suggestions
 */
exports.getAutocompleteSuggestions = onCall(async (request) => {
    try {
        const { input } = request.data;

        if (!input) {
            throw new Error("Input is required");
        }

        logger.info(`🔍 Getting autocomplete for: ${input}`);

        const response = await fetch(`${PLACES_BASE_URL}/places:autocomplete`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
                "X-Goog-FieldMask": "suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat",
            },
            body: JSON.stringify({
                input: input,
                includedPrimaryTypes: ["locality", "country", "administrative_area_level_1"],
            }),
        });

        if (!response.ok) {
            throw new Error(`Autocomplete request failed: ${response.status}`);
        }

        const data = await response.json();
        const suggestionCount = data.suggestions && data.suggestions.length ? data.suggestions.length : 0;
        logger.info(`✅ Autocomplete returned ${suggestionCount} suggestions`);

        return data;
    } catch (error) {
        logger.error("❌ Error in getAutocompleteSuggestions:", error);
        throw new Error(`Get autocomplete suggestions failed: ${error.message}`);
    }
});

/**
 * Get popular places/attractions for a specific location
 */
exports.getPopularPlaces = onCall(async (request) => {
    try {
        const { placeId, maxResults = 20 } = request.data;

        if (!placeId) {
            throw new Error("Place ID is required");
        }

        logger.info(`🏛️ Getting popular places for: ${placeId}`);

        // First, get the location of the main place
        const placeResponse = await fetch(`${PLACES_BASE_URL}/places/${placeId}`, {
            headers: {
                "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
                "X-Goog-FieldMask": "location,displayName",
            },
        });

        if (!placeResponse.ok) {
            throw new Error(`Place location request failed: ${placeResponse.status}`);
        }

        const placeData = await placeResponse.json();
        const location = placeData.location;
        const placeName = placeData.displayName && placeData.displayName.text ? placeData.displayName.text : "Unknown";

        if (!location) {
            throw new Error("Place location not found");
        }

        logger.info(`📍 Searching popular places near: ${placeName}`);

        // Search for popular places nearby using the same format as getPlacePhotos
        const nearbyResponse = await fetch(`${PLACES_BASE_URL}/places:searchNearby`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
                "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.types,places.photos",
            },
            body: JSON.stringify({
                locationRestriction: {
                    circle: {
                        center: {
                            latitude: location.latitude,
                            longitude: location.longitude,
                        },
                        radius: 30000.0, // 30km radius
                    },
                },
                includedTypes: ["tourist_attraction", "park", "zoo", "restaurant"],
                excludedTypes: ["hotel"],
                maxResultCount: maxResults,
            }),
        });

        if (!nearbyResponse.ok) {
            throw new Error(`Nearby search failed: ${nearbyResponse.status}`);
        }

        const nearbyData = await nearbyResponse.json();
        const places = nearbyData.places || [];

        // Transform places to match our Place model format and get photo URLs
        const popularPlaces = [];
        for (const place of places) {
            const photos = place.photos || [];
            const photoUrls = [];

            // Get photo URLs for the first few photos
            for (let i = 0; i < Math.min(photos.length, 3); i++) {
                const photoName = photos[i].name;
                const photoUrl = `https://places.googleapis.com/v1/${photoName}/media?maxWidthPx=800&key=${GOOGLE_PLACES_API_KEY}`;
                photoUrls.push(photoUrl);
            }

            const transformedPlace = {
                id: place.id,
                placeId: place.id,
                displayName: place.displayName,
                formattedAddress: place.formattedAddress,
                location: place.location,
                rating: place.rating,
                userRatingCount: place.userRatingCount,
                types: place.types || [],
                photos: place.photos || [],
                photoUrls: photoUrls,
            };

            popularPlaces.push(transformedPlace);
        }

        logger.info(`✅ Found ${popularPlaces.length} popular places`);

        return { places: popularPlaces };
    } catch (error) {
        logger.error("❌ Error in getPopularPlaces:", error);
        throw new Error(`Get popular places failed: ${error.message}`);
    }
});

/**
 * Automatically classify document type when a new document is added to Firestore
 * Triggered on: trips/{tripId}/documents/{documentId}
 */
exports.classifyDocumentOnCreate = onDocumentCreated(
    {
        document: "trips/{tripId}/documents/{documentId}",
        region: "us-central1",
    },
    async (event) => {
        try {
            const documentData = event.data.data();
            const tripId = event.params.tripId;
            const documentId = event.params.documentId;

            const fileName = documentData.original_file_name || documentData.file_name;
            const downloadUrl = documentData.download_url;

            if (!downloadUrl || !fileName) {
                logger.warn(`Missing data for document classification: ${documentId}`);
                return;
            }

            logger.info(`🤖 Auto-classifying document: ${fileName} (${documentId})`);

            // Use Gemini Vision API for better document understanding
            const { GoogleGenerativeAI } = require("@google/generative-ai");

            const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
            if (!GEMINI_API_KEY) {
                logger.warn("GEMINI_API_KEY not found, falling back to filename-based classification");
                // Fallback to simple filename-based classification
                const documentType = classifyByFilename(fileName);
                if (documentType !== "other") {
                    await updateDocumentType(tripId, documentId, documentType);
                }
                return;
            }

            const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
            const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

            const prompt = `Analyze this document image and classify it into ONE of these categories:
- passport: Passport documents (any country)
- visa: Visa documents, entry permits, or immigration stamps
- flight: Flight tickets, boarding passes, airline confirmations
- train: Train tickets, railway bookings, rail passes
- hotel: Hotel bookings, accommodation confirmations, resort reservations
- rental: Car rental agreements, vehicle hire documents
- cruise: Cruise tickets, ship boarding passes, maritime bookings
- insurance: Travel insurance policies, coverage documents
- other: Any other travel-related documents

Look at the document layout, logos, headers, text content, and visual elements.
Consider the overall document design and purpose.

Respond with ONLY the category name (lowercase, no explanation or additional text).`;

            // Fetch the image from the download URL
            const imageResponse = await fetch(downloadUrl);
            if (!imageResponse.ok) {
                throw new Error(`Failed to fetch image: ${imageResponse.status}`);
            }

            const imageBuffer = await imageResponse.arrayBuffer();
            const imageData = {
                inlineData: {
                    data: Buffer.from(imageBuffer).toString('base64'),
                    mimeType: imageResponse.headers.get('content-type') || 'image/jpeg'
                }
            };

            logger.info(`🤖 Sending document to Gemini for analysis: ${fileName}`);

            const result = await model.generateContent([prompt, imageData]);
            const response = await result.response;
            const classification = response.text().trim().toLowerCase();

            // Validate classification result
            const validTypes = ["passport", "visa", "flight", "train", "hotel", "rental", "cruise", "insurance", "other"];
            const documentType = validTypes.includes(classification) ? classification : "other";

            logger.info(`🤖 Gemini classified document as: ${documentType}`);

            // Only update if we found a specific type (not 'other')
            if (documentType !== "other") {
                logger.info(`✅ Document classified as: ${documentType}, updating Firestore...`);

                // Update the document in Firestore
                await admin.firestore()
                    .collection("trips")
                    .doc(tripId)
                    .collection("documents")
                    .doc(documentId)
                    .update({
                        type: documentType,
                        classified_at: admin.firestore.Timestamp.now(),
                    });

                logger.info(`✅ Document type updated in Firestore: ${documentType}`);
            } else {
                logger.info(`ℹ️ Document remains as 'other' type: ${fileName}`);
            }

        } catch (error) {
            logger.error("❌ Error in document classification trigger:", error);
            // Don't throw error to avoid function retries
        }
    }
);

// Helper function for filename-based classification fallback
function classifyByFilename(fileName) {
    const name = fileName.toLowerCase();

    if (name.includes("passport")) return "passport";
    if (name.includes("visa")) return "visa";
    if (name.includes("boarding") || name.includes("flight") || name.includes("ticket")) return "flight";
    if (name.includes("train") || name.includes("rail")) return "train";
    if (name.includes("hotel") || name.includes("booking")) return "hotel";
    if (name.includes("rental") || name.includes("car")) return "rental";
    if (name.includes("cruise") || name.includes("ship")) return "cruise";
    if (name.includes("insurance") || name.includes("policy")) return "insurance";

    return "other";
}

// Helper function to update document type
async function updateDocumentType(tripId, documentId, documentType) {
    try {
        await admin.firestore()
            .collection("trips")
            .doc(tripId)
            .collection("documents")
            .doc(documentId)
            .update({
                type: documentType,
                classified_at: admin.firestore.Timestamp.now(),
            });

        logger.info(`✅ Document type updated: ${documentType}`);
    } catch (error) {
        logger.error(`❌ Error updating document type: ${error}`);
    }
}