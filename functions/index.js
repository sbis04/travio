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

                // Update the document in Firestore with classification
                const updateData = {
                    type: documentType,
                    classified_at: admin.firestore.Timestamp.now(),
                };

                // If it's a flight document, extract flight information
                if (documentType === "flight") {
                    logger.info(`✈️ Extracting flight information from: ${fileName}`);
                    try {
                        const extractionResult = await extractFlightInformation(imageData, fileName);
                        if (extractionResult && extractionResult.enhanced) {
                            logger.info(`✅ Flight information extracted: ${JSON.stringify(extractionResult.enhanced, null, 2)}`);

                            // Store flight info and airport details in subcollections
                            await storeFlightInfoSubcollections(tripId, documentId, extractionResult.enhanced, extractionResult.airportData);
                        }
                    } catch (flightError) {
                        logger.warn(`⚠️ Failed to extract flight info: ${flightError.message}`);
                        // Continue with classification even if flight extraction fails
                    }
                }

                await admin.firestore()
                    .collection("trips")
                    .doc(tripId)
                    .collection("documents")
                    .doc(documentId)
                    .update(updateData);

                logger.info(`✅ Document updated in Firestore: ${documentType}`);
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

// Extract flight information from flight documents using Gemini
async function extractFlightInformation(imageData, fileName) {
    try {
        const { GoogleGenerativeAI } = require("@google/generative-ai");
        const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

        if (!GEMINI_API_KEY) {
            throw new Error("GEMINI_API_KEY not available for flight extraction");
        }

        const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

        const extractionPrompt = `Extract flight information from this boarding pass/flight ticket image.
Return a JSON object with the following fields (use null for missing information):

{
  "flight_number": "flight number exactly as shown (e.g., 6E123, AI101, UK955, 6E 123)",
  "airline": "airline name (e.g., Air India, IndiGo, Vistara)",
  "origin_code": "origin airport IATA code (e.g., DEL, BOM, CCU, BLR)",
  "destination_code": "destination airport IATA code (e.g., BLR, MAA, HYD, DEL)",
  "departure_time": "departure date and time in ISO format (YYYY-MM-DDTHH:MM:SS)",
  "arrival_time": "arrival date and time in ISO format (YYYY-MM-DDTHH:MM:SS)",
  "gate": "gate number if available",
  "terminal": "terminal information if available",
  "seat": "seat number (e.g., 12A, 23F)",
  "confirmation_number": "booking/PNR reference",
  "passenger_name": "passenger name",
  "ticket_number": "ticket number if visible",
  "class_of_service": "travel class (Economy, Business, First)",
  "status": "flight status if mentioned (Confirmed, Cancelled, Delayed)"
}

CRITICAL INSTRUCTIONS:
- Extract flight number EXACTLY as it appears (including spaces, dashes)
- Look for patterns like: "6E123", "6E 123", "6E-123", "AI101", "UK955"
- Use proper 3-letter IATA airport codes (DEL, BOM, CCU, BLR, MAA, HYD, etc.)
- Format dates as ISO 8601: YYYY-MM-DDTHH:MM:SS (24-hour format)
- Return ONLY valid JSON, no additional text or explanations
- Use null for any missing fields`;

        logger.info(`🔍 Analyzing flight document with Gemini...`);

        const geminiResult = await model.generateContent([extractionPrompt, imageData]);
        const response = await geminiResult.response;
        let extractedText = response.text().trim();

        // Clean up the response to ensure valid JSON
        extractedText = extractedText.replace(/```json\s*/, '').replace(/```\s*$/, '');

        logger.info(`📄 Raw extraction result: ${extractedText}`);

        // Parse the JSON response
        let flightData;
        try {
            flightData = JSON.parse(extractedText);
            logger.info(`🎯 Gemini extracted flight data: ${JSON.stringify(flightData, null, 2)}`);
        } catch (parseError) {
            logger.warn(`⚠️ Failed to parse JSON response: ${parseError.message}`);
            logger.warn(`📄 Raw response: ${extractedText}`);
            return null;
        }

        // Enhance extracted data with flight API and Places API
        const enhancedResult = await enhanceFlightData(flightData);

        return enhancedResult;

    } catch (error) {
        logger.error(`❌ Error extracting flight information: ${error.message}`);
        throw error;
    }
}

// Enhance flight data with Places API for airport information
async function enhanceFlightData(flightData) {
    try {
        logger.info(`🌍 Enhancing flight data with airport locations...`);

        const enhanced = { ...flightData };

        // Convert ISO string dates to Firestore Timestamps
        if (enhanced.departure_time && typeof enhanced.departure_time === 'string') {
            try {
                const departureDate = new Date(enhanced.departure_time);
                if (!isNaN(departureDate.getTime())) {
                    enhanced.departure_time = admin.firestore.Timestamp.fromDate(departureDate);
                    logger.info(`📅 Converted departure time: ${enhanced.departure_time.toDate()}`);
                } else {
                    logger.warn(`⚠️ Invalid departure time format: ${enhanced.departure_time}`);
                    enhanced.departure_time = null;
                }
            } catch (dateError) {
                logger.warn(`⚠️ Error parsing departure time: ${dateError.message}`);
                enhanced.departure_time = null;
            }
        }

        if (enhanced.arrival_time && typeof enhanced.arrival_time === 'string') {
            try {
                const arrivalDate = new Date(enhanced.arrival_time);
                if (!isNaN(arrivalDate.getTime())) {
                    enhanced.arrival_time = admin.firestore.Timestamp.fromDate(arrivalDate);
                    logger.info(`📅 Converted arrival time: ${enhanced.arrival_time.toDate()}`);
                } else {
                    logger.warn(`⚠️ Invalid arrival time format: ${enhanced.arrival_time}`);
                    enhanced.arrival_time = null;
                }
            } catch (dateError) {
                logger.warn(`⚠️ Error parsing arrival time: ${dateError.message}`);
                enhanced.arrival_time = null;
            }
        }

        // Add extracted timestamp
        enhanced.extracted_at = admin.firestore.Timestamp.now();

        // Try to enhance with flight API (free plan compatible)
        if (enhanced.flight_number && enhanced.departure_time) {
            try {
                logger.info(`✈️ Attempting to enhance flight data for: ${enhanced.flight_number}`);

                // Try to get basic flight data (compatible with free plan)
                const basicFlightData = await getBasicFlightData(enhanced);
                if (basicFlightData) {
                    Object.assign(enhanced, basicFlightData);
                    logger.info(`✅ Enhanced with basic flight data`);
                } else {
                    logger.info(`📊 No API data available, using calculation-based approach`);
                }

                // Always try to calculate arrival time if missing
                if (!enhanced.arrival_time) {
                    const calculatedArrival = await calculateFlightArrivalTime(enhanced, enhanced);
                    if (calculatedArrival) {
                        enhanced.arrival_time = calculatedArrival;
                        enhanced.status = enhanced.status || 'Estimated';
                        logger.info(`✅ Calculated arrival time using duration estimation`);
                    }
                }
            } catch (apiError) {
                logger.warn(`⚠️ Flight API error: ${apiError.message}`);

                // Fallback to calculation-based approach
                logger.info(`🔄 Using calculation-only approach...`);
                if (!enhanced.arrival_time) {
                    const calculatedArrival = await calculateFlightArrivalTime(enhanced, enhanced);
                    if (calculatedArrival) {
                        enhanced.arrival_time = calculatedArrival;
                        enhanced.status = 'Estimated';
                        logger.info(`✅ Used calculation fallback for arrival time`);
                    }
                }
            }
        }

        // Get airport information from Places API and store in subcollections
        const airportData = {};

        if (enhanced.origin_code) {
            const originAirport = await findAirportByCode(enhanced.origin_code);
            if (originAirport) {
                enhanced.origin_place_name = originAirport.name;
                enhanced.origin_place_id = originAirport.place_id;
                airportData.origin = originAirport;
            }
        }

        if (enhanced.destination_code) {
            const destAirport = await findAirportByCode(enhanced.destination_code);
            if (destAirport) {
                enhanced.destination_place_name = destAirport.name;
                enhanced.destination_place_id = destAirport.place_id;
                airportData.destination = destAirport;
            }
        }

        logger.info(`✅ Enhanced flight data: ${enhanced.origin_code} → ${enhanced.destination_code}`);

        // Return both enhanced data and airport details for subcollections
        return { enhanced, airportData };

    } catch (error) {
        logger.warn(`⚠️ Failed to enhance flight data: ${error.message}`);
        // Return original data even if enhancement fails
        return {
            enhanced: {
                ...flightData,
                extracted_at: admin.firestore.Timestamp.now(),
            },
            airportData: {},
        };
    }
}

// Find airport information using Places API
async function findAirportByCode(airportCode) {
    try {
        logger.info(`🔍 Finding airport info for: ${airportCode}`);

        // Search for airport using the IATA code
        const searchQuery = `${airportCode} airport`;

        const response = await fetch(`${PLACES_BASE_URL}/places:searchText`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
                "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location",
            },
            body: JSON.stringify({
                textQuery: searchQuery,
                includedType: "airport",
                maxResultCount: 3,
            }),
        });

        if (!response.ok) {
            logger.warn(`⚠️ Places API search failed: ${response.status}`);
            return null;
        }

        const data = await response.json();
        const places = data.places || [];

        if (places.length === 0) {
            logger.warn(`⚠️ No airport found for code: ${airportCode}`);
            return null;
        }

        // Find the best match (usually the first result)
        const airport = places[0];
        const airportName = airport.displayName && airport.displayName.text ? airport.displayName.text : `${airportCode} Airport`;

        logger.info(`✅ Found airport: ${airportName} (${airport.id})`);

        return {
            place_id: airport.id,
            name: airportName,
            address: airport.formattedAddress,
            location: airport.location,
        };

    } catch (error) {
        logger.warn(`⚠️ Error finding airport ${airportCode}: ${error.message}`);
        return null;
    }
}

// Store flight info and airport details in organized subcollections
async function storeFlightInfoSubcollections(tripId, documentId, flightInfo, airportData) {
    try {
        logger.info(`✈️ Storing flight info subcollections for document: ${documentId}`);

        const batch = admin.firestore().batch();
        const documentRef = admin.firestore()
            .collection("trips")
            .doc(tripId)
            .collection("documents")
            .doc(documentId);

        // Store main flight information in flight_info subcollection
        const flightInfoRef = documentRef.collection("flight_info").doc("details");
        batch.set(flightInfoRef, flightInfo);
        logger.info(`✈️ Adding flight details: ${flightInfo.flight_number}`);

        // Store origin place details inside flight_info subcollection
        if (airportData.origin) {
            const originRef = documentRef.collection("flight_info").doc("origin_place");
            batch.set(originRef, {
                place_id: airportData.origin.place_id,
                name: airportData.origin.name,
                formatted_address: airportData.origin.address,
                location: airportData.origin.location,
                place_type: "airport",
                created_at: admin.firestore.Timestamp.now(),
            });
            logger.info(`📍 Adding origin place: ${airportData.origin.name}`);
        }

        // Store destination place details inside flight_info subcollection
        if (airportData.destination) {
            const destinationRef = documentRef.collection("flight_info").doc("destination_place");
            batch.set(destinationRef, {
                place_id: airportData.destination.place_id,
                name: airportData.destination.name,
                formatted_address: airportData.destination.address,
                location: airportData.destination.location,
                place_type: "airport",
                created_at: admin.firestore.Timestamp.now(),
            });
            logger.info(`📍 Adding destination place: ${airportData.destination.name}`);
        }

        await batch.commit();
        logger.info(`✅ Flight info subcollections stored successfully`);

    } catch (error) {
        logger.error(`❌ Error storing flight info subcollections: ${error.message}`);
        // Don't throw error - this is not critical for the main flow
    }
}

// Get basic flight data (free plan compatible)
async function getBasicFlightData(flightData) {
    try {
        const AVIATIONSTACK_API_KEY = process.env.AVIATIONSTACK_API_KEY;

        if (!AVIATIONSTACK_API_KEY) {
            logger.info("AVIATIONSTACK_API_KEY not found, skipping API enhancement");
            return null;
        }

        logger.info(`✈️ Trying basic flight data for: ${flightData.flight_number}`);

        // For free plan, we'll skip the API call entirely and rely on calculation
        // The free plan has very limited access and the 403 error indicates function restriction
        logger.info(`📊 Free plan detected, using calculation-based approach only`);
        return null;

        // Note: If you upgrade to a paid plan, you can uncomment the code below:
        /*
        // Extract airline code and flight number
        const flightNumber = flightData.flight_number.toString().trim().toUpperCase();
        
        // Format departure date for API (YYYY-MM-DD)
        const departureDate = flightData.departure_time.toDate();
        const dateStr = departureDate.toISOString().split('T')[0];

        // Try basic endpoint that might be available in free plan
        const apiUrl = `https://api.aviationstack.com/v1/flights`;
        const params = new URLSearchParams({
            access_key: AVIATIONSTACK_API_KEY,
            flight_iata: flightNumber,
            flight_date: dateStr,
            limit: 1
        });

        const response = await fetch(`${apiUrl}?${params}`);
        
        if (!response.ok) {
            logger.warn(`⚠️ AviationStack API not available in free plan: ${response.status}`);
            return null;
        }

        const apiData = await response.json();
        // ... process response
        */

    } catch (error) {
        logger.warn(`⚠️ Basic flight data error: ${error.message}`);
        return null;
    }
}

// Calculate arrival time when AviationStack API doesn't provide it
async function calculateFlightArrivalTime(originalFlightData, apiFlightData) {
    try {
        logger.info(`📊 Calculating arrival time for ${originalFlightData.origin_code} → ${originalFlightData.destination_code}`);

        // Method 1: Use original extracted duration if both times were extracted
        if (originalFlightData.departure_time && originalFlightData.arrival_time) {
            const originalDeparture = originalFlightData.departure_time.toDate();
            const originalArrival = originalFlightData.arrival_time.toDate();
            const extractedDuration = originalArrival.getTime() - originalDeparture.getTime();

            // Use real departure time from API if available, otherwise use extracted
            const realDeparture = apiFlightData.departure_time
                ? apiFlightData.departure_time.toDate()
                : originalDeparture;

            const calculatedArrival = new Date(realDeparture.getTime() + extractedDuration);

            logger.info(`✅ Calculated arrival using extracted duration: ${calculatedArrival.toISOString()}`);
            logger.info(`⏱️ Flight duration: ${Math.round(extractedDuration / (1000 * 60))} minutes`);

            return admin.firestore.Timestamp.fromDate(calculatedArrival);
        }

        // Method 2: Use route-based estimation
        if (originalFlightData.origin_code && originalFlightData.destination_code) {
            const estimatedDuration = getEstimatedFlightDuration(
                originalFlightData.origin_code,
                originalFlightData.destination_code
            );

            if (estimatedDuration) {
                const departureTime = apiFlightData.departure_time
                    ? apiFlightData.departure_time.toDate()
                    : originalFlightData.departure_time.toDate();

                const estimatedArrival = new Date(departureTime.getTime() + estimatedDuration);

                logger.info(`✅ Estimated arrival using route data: ${estimatedArrival.toISOString()}`);
                logger.info(`⏱️ Estimated duration: ${Math.round(estimatedDuration / (1000 * 60))} minutes`);

                return admin.firestore.Timestamp.fromDate(estimatedArrival);
            }
        }

        logger.warn(`⚠️ Could not calculate arrival time`);
        return null;

    } catch (error) {
        logger.warn(`⚠️ Error calculating arrival time: ${error.message}`);
        return null;
    }
}

// Get estimated flight duration between airports
function getEstimatedFlightDuration(originCode, destinationCode) {
    try {
        // Common flight durations (in milliseconds) - can be expanded
        const commonRoutes = {
            // India domestic routes
            'CCU-BLR': 2.5 * 60 * 60 * 1000, // 2.5 hours
            'BLR-CCU': 2.5 * 60 * 60 * 1000,
            'DEL-BOM': 2.5 * 60 * 60 * 1000,
            'BOM-DEL': 2.5 * 60 * 60 * 1000,
            'DEL-BLR': 2.5 * 60 * 60 * 1000,
            'BLR-DEL': 2.5 * 60 * 60 * 1000,
            'CCU-DEL': 2 * 60 * 60 * 1000,
            'DEL-CCU': 2 * 60 * 60 * 1000,
            'BOM-CCU': 2.5 * 60 * 60 * 1000,
            'CCU-BOM': 2.5 * 60 * 60 * 1000,
            'DEL-MAA': 2.5 * 60 * 60 * 1000,
            'MAA-DEL': 2.5 * 60 * 60 * 1000,
            'BOM-BLR': 1.5 * 60 * 60 * 1000,
            'BLR-BOM': 1.5 * 60 * 60 * 1000,

            // International routes (examples)
            'DEL-JFK': 15 * 60 * 60 * 1000, // 15 hours
            'JFK-DEL': 13 * 60 * 60 * 1000, // 13 hours (shorter due to jet stream)
            'BOM-LHR': 9 * 60 * 60 * 1000,  // 9 hours
            'LHR-BOM': 8.5 * 60 * 60 * 1000,
            'DEL-DXB': 3.5 * 60 * 60 * 1000, // 3.5 hours
            'DXB-DEL': 3.5 * 60 * 60 * 1000,
            'BOM-SIN': 5.5 * 60 * 60 * 1000, // 5.5 hours
            'SIN-BOM': 5.5 * 60 * 60 * 1000,
        };

        const routeKey = `${originCode}-${destinationCode}`;
        const reverseRouteKey = `${destinationCode}-${originCode}`;

        // Check for exact route or reverse route
        if (commonRoutes[routeKey]) {
            logger.info(`✅ Found route duration for ${routeKey}: ${commonRoutes[routeKey] / (1000 * 60)} minutes`);
            return commonRoutes[routeKey];
        } else if (commonRoutes[reverseRouteKey]) {
            logger.info(`✅ Found reverse route duration for ${routeKey}: ${commonRoutes[reverseRouteKey] / (1000 * 60)} minutes`);
            return commonRoutes[reverseRouteKey];
        }

        // Fallback: Use a reasonable default based on route type
        const isInternational = originCode.length === 3 && destinationCode.length === 3 &&
            originCode.substring(0, 1) !== destinationCode.substring(0, 1);

        const defaultDuration = isInternational
            ? 6 * 60 * 60 * 1000  // 6 hours for international
            : 2 * 60 * 60 * 1000; // 2 hours for domestic

        logger.info(`⚠️ No specific route data for ${routeKey}, using default: ${defaultDuration / (1000 * 60)} minutes`);
        return defaultDuration;

    } catch (error) {
        logger.warn(`⚠️ Error estimating flight duration: ${error.message}`);
        return 2 * 60 * 60 * 1000; // 2 hour fallback
    }
}