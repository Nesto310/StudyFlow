from datetime import datetime, time, timedelta, timezone
from secrets import token_urlsafe

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.models import AvailabilitySlot, Subject, Task, User

# A reserved example domain remains compatible with the existing EmailStr schema.
DEMO_EMAIL = "demo@studyflow.example.com"


def get_demo_user(db: Session) -> User:
    query = select(User).where(User.email == DEMO_EMAIL).with_for_update()
    user = db.scalar(query)
    if user is None:
        try:
            with db.begin_nested():
                user = User(email=DEMO_EMAIL, password_hash=hash_password(token_urlsafe(48)))
                db.add(user)
                db.flush()
        except IntegrityError:
            # A concurrent first request may already have created the shared demo user.
            user = db.scalar(query)
            if user is None:
                raise

    has_subjects = db.scalar(select(Subject.id).where(Subject.user_id == user.id).limit(1))
    has_tasks = db.scalar(select(Task.id).join(Subject).where(Subject.user_id == user.id).limit(1))
    has_slots = db.scalar(select(AvailabilitySlot.id).where(AvailabilitySlot.user_id == user.id).limit(1))
    if not any((has_subjects, has_tasks, has_slots)):
        now = datetime.now(timezone.utc)
        examples = [
            ("Algoritmos", "Revisar árvores AVL", 90, 2),
            ("Banco de Dados", "Revisar normalização", 60, 4),
            ("Engenharia de Software", "Finalizar documentação", 120, 6),
        ]
        for name, title, minutes, days in examples:
            subject = Subject(user_id=user.id, name=name)
            db.add(Task(subject=subject, title=title, estimated_minutes=minutes,
                        due_date=now + timedelta(days=days), is_completed=False))
        db.add_all([
            AvailabilitySlot(user_id=user.id, day_of_week=day, start_time=time(19),
                             end_time=time(21), repeat_next_week=True)
            for day in range(1, 8)
        ])
    return user
