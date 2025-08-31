const { onCall } = require("firebase-functions/v2/https");
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