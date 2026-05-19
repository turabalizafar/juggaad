"""
Firebase Auth JWT verification as a FastAPI dependency.
Extracts the Bearer token from the Authorization header and verifies it
against Firebase Admin SDK. Returns the authenticated user's UID.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

import firebase_admin.auth

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> str:
    """
    FastAPI dependency that verifies Firebase ID token.

    Returns:
        str: The authenticated user's UID.

    Raises:
        HTTPException 401: If token is missing, expired, or invalid.
    """
    token = credentials.credentials

    try:
        decoded = firebase_admin.auth.verify_id_token(token)
        return decoded["uid"]
    except firebase_admin.auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "error": "auth_expired",
                "message": "Firebase token has expired. Please sign in again.",
                "code": 401,
            },
        )
    except firebase_admin.auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "error": "auth_invalid",
                "message": "Invalid Firebase token.",
                "code": 401,
            },
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "error": "auth_required",
                "message": "Authentication required. Provide a valid Firebase Bearer token.",
                "code": 401,
            },
        )
