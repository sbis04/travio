# Travio Cloud Functions

This directory contains Firebase Cloud Functions that securely handle Google Places API calls.

## Setup

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Configure environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env and add your Google Places API key
   ```

3. **Deploy functions**:
   ```bash
   firebase deploy --only functions
   ```

## Environment Variables

Create a `.env` file with the following variables:

```
GOOGLE_PLACES_API_KEY=your_actual_google_places_api_key_here
```

## Available Functions

### `searchDestinations`
- **Purpose**: Search for travel destinations (cities, countries)
- **Input**: `{ input: "Paris" }`
- **Output**: `{ places: [...] }`

### `getPlacePhotos`
- **Purpose**: Get photos for a specific place
- **Input**: `{ placeId: "ChIJ...", maxPhotos: 20, maxWidth: 800 }`
- **Output**: `{ photos: ["url1", "url2", ...] }`

### `getPlaceDetails`
- **Purpose**: Get detailed information about a place
- **Input**: `{ placeId: "ChIJ..." }`
- **Output**: `{ place: {...} }`

### `getAutocompleteSuggestions`
- **Purpose**: Get autocomplete suggestions for search
- **Input**: `{ input: "Par" }`
- **Output**: `{ suggestions: [...] }`

## Security

- ✅ API key stored securely in environment variables
- ✅ Functions handle all external API calls
- ✅ Client never sees the API key
- ✅ CORS enabled for web app access

## Development

```bash
# Run functions locally
npm run serve

# View logs
npm run logs

# Test functions
firebase functions:shell
```
