"""Scheduler for automatic Zendesk synchronization"""
import asyncio
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from datetime import datetime
from database import SessionLocal, User
from services.knowledge_service import KnowledgeService
from config import settings
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

scheduler = BackgroundScheduler()
scheduler.start()

def sync_zendesk_automatic():
    """Automatic Zendesk synchronization task"""
    logger.info(f"Starting automatic Zendesk sync at {datetime.utcnow()}")
    
    db = SessionLocal()
    try:
        # Get first admin user or create a system user
        admin_user = db.query(User).filter(User.is_admin == True).first()
        admin_user_id = admin_user.id if admin_user else None
        
        service = KnowledgeService(db)
        result = service.sync_zendesk(created_by=admin_user_id)
        
        if result.get("success"):
            logger.info(
                f"Zendesk sync completed: {result.get('added')} added, "
                f"{result.get('updated')} updated, {result.get('errors')} errors"
            )
        else:
            logger.error(f"Zendesk sync failed: {result.get('error')}")
            
    except Exception as e:
        logger.error(f"Error in automatic Zendesk sync: {str(e)}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

def setup_zendesk_scheduler(enabled: bool = False, hour: int = 2, minute: int = 0):
    """Setup automatic Zendesk synchronization scheduler
    
    Args:
        enabled: Enable automatic synchronization
        hour: Hour of day to sync (0-23)
        minute: Minute of hour to sync (0-59)
    """
    # Remove existing jobs
    try:
        scheduler.remove_job('zendesk_sync')
    except:
        pass
    
    if enabled:
        # Schedule daily sync at specified time
        scheduler.add_job(
            sync_zendesk_automatic,
            trigger=CronTrigger(hour=hour, minute=minute),
            id='zendesk_sync',
            name='Zendesk Automatic Sync',
            replace_existing=True
        )
        logger.info(f"Zendesk automatic sync enabled: Daily at {hour:02d}:{minute:02d} UTC")
    else:
        logger.info("Zendesk automatic sync is disabled")

def get_scheduler_status():
    """Get scheduler status"""
    job = scheduler.get_job('zendesk_sync')
    if job:
        return {
            "enabled": True,
            "next_run": job.next_run_time.isoformat() if job.next_run_time else None,
            "trigger": str(job.trigger)
        }
    return {"enabled": False}


