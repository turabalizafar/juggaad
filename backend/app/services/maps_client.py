"""
Google Maps Distance Matrix API client.
Calls the real Distance Matrix endpoint and returns distance_km + eta_minutes
for each origin→destination pair.
"""

import requests


class MapsClient:
    """Wrapper around the Google Maps Distance Matrix API."""

    DISTANCE_MATRIX_URL = "https://maps.googleapis.com/maps/api/distancematrix/json"

    def __init__(self, api_key: str) -> None:
        """
        Args:
            api_key: Google Maps API key with Distance Matrix API enabled.

        Raises:
            ValueError: If api_key is empty.
        """
        if not api_key:
            raise ValueError(
                "MAPS_API_KEY is required to initialise the Maps client."
            )
        self._api_key = api_key

    def get_distance_matrix(
        self,
        origin_lat: float,
        origin_lng: float,
        destinations: list[tuple[float, float]],
    ) -> list[dict]:
        """
        Call Distance Matrix API for one origin and multiple destinations.

        Args:
            origin_lat: User's latitude.
            origin_lng: User's longitude.
            destinations: List of (lat, lng) tuples for providers.

        Returns:
            list[dict]: One dict per destination with keys:
                - distance_km (float)
                - eta_minutes (int)
                - status (str): 'OK' or error status from API

        Raises:
            requests.RequestException: On HTTP failure.
        """
        if not destinations:
            return []

        # Format as "lat,lng|lat,lng|..."
        origin_str = f"{origin_lat},{origin_lng}"
        dest_str = "|".join(f"{lat},{lng}" for lat, lng in destinations)

        params = {
            "origins": origin_str,
            "destinations": dest_str,
            "key": self._api_key,
            "mode": "driving",
        }

        resp = requests.get(self.DISTANCE_MATRIX_URL, params=params, timeout=10)
        resp.raise_for_status()
        data = resp.json()

        results = []
        if data.get("status") != "OK":
            # Return fallback for all destinations
            return [
                {"distance_km": 0.0, "eta_minutes": 0, "status": data.get("status", "UNKNOWN")}
                for _ in destinations
            ]

        elements = data.get("rows", [{}])[0].get("elements", [])
        for element in elements:
            if element.get("status") == "OK":
                distance_m = element["distance"]["value"]  # metres
                duration_s = element["duration"]["value"]   # seconds
                results.append({
                    "distance_km": round(distance_m / 1000, 2),
                    "eta_minutes": max(1, round(duration_s / 60)),
                    "status": "OK",
                })
            else:
                results.append({
                    "distance_km": 0.0,
                    "eta_minutes": 0,
                    "status": element.get("status", "UNKNOWN"),
                })

        return results
