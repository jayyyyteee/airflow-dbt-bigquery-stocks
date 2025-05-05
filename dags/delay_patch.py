"""
This module patches yfinance to add delays between API calls to avoid rate limiting.
Import this before any imports of yfinance in your DAGs.

Example usage (add to the top of your DAG file):
from delay_patch import apply_yfinance_patch
apply_yfinance_patch()
"""

import time
import random
import functools
import logging

logger = logging.getLogger(__name__)

def apply_yfinance_patch():
    """Apply monkey patch to yfinance to add delays between API calls"""
    try:
        import yfinance as yf
        
        # Store the original history method
        original_history = yf.Ticker.history
        
        # Define the wrapper function that adds delays
        @functools.wraps(original_history)
        def history_with_delay(self, *args, **kwargs):
            # Add a random delay between 2-5 seconds
            delay = random.uniform(2, 5)
            logger.info(f"Adding {delay:.2f}s delay before API call for {self.ticker}")
            time.sleep(delay)
            
            # Call the original method
            return original_history(self, *args, **kwargs)
        
        # Apply the monkey patch
        yf.Ticker.history = history_with_delay
        logger.info("Successfully applied yfinance delay patch")
        
        # Print the current version for debugging
        logger.info(f"Using yfinance version: {yf.__version__}")
        return True
    except Exception as e:
        logger.error(f"Failed to apply yfinance patch: {e}")
        return False 