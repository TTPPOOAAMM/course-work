from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import models, schemas, auth
from app.database import get_db

router = APIRouter(
    prefix="/api/users",
    tags=["Users / Profiles"]
)

@router.get("/me", response_model=schemas.UserProfileResponse)
def get_my_profile(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Получить профиль текущего авторизованного пользователя"""
    return current_user

@router.put("/me/profile", response_model=schemas.ProfileResponse)
def update_my_profile(
    profile_data: schemas.ProfileUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Создать или обновить свою анкету волонтера/организатора"""
    profile = db.query(models.Profile).filter(models.Profile.user_id == current_user.ID_user).first()

    if not profile:
        profile = models.Profile(user_id=current_user.ID_user)
        db.add(profile)
    
    if profile_data.phone is not None:
        profile.phone = profile_data.phone
    if profile_data.birth_date is not None:
        profile.birth_date = profile_data.birth_date
    if profile_data.interests is not None:
        profile.interests = profile_data.interests

    if profile_data.skills is not None:
        db.query(models.VolunteerSkill).filter(models.VolunteerSkill.profile_id == current_user.ID_user).delete()
        for skill_name in profile_data.skills:
            new_skill = models.VolunteerSkill(profile_id=current_user.ID_user, skill_name=skill_name)
            db.add(new_skill)

    db.commit()
    db.refresh(profile)
    return profile

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_my_account(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Логическое удаление профиля текущего пользователя"""
    
    current_user.is_deleted = True

    if current_user.role_id == 2:  # Организатор
        active_events = db.query(models.Event).filter(
            models.Event.organizer_id == current_user.ID_user,
            models.Event.status == models.EventStatus.active
        ).all()
        
        for event in active_events:
            event.status = models.EventStatus.archived
            
            for app in event.applications:
                if app.status == models.AppStatus.pending:
                    app.status = models.AppStatus.expired

    elif current_user.role_id == 1:  # Волонтер
        active_applications = db.query(models.Application).filter(
            models.Application.volunteer_id == current_user.ID_user,
            models.Application.status.in_([models.AppStatus.pending, models.AppStatus.approved])
        ).all()
        
        for app in active_applications:
            app.status = models.AppStatus.expired

    db.commit()
    
    return None