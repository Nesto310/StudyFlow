from datetime import datetime, time, timezone
from uuid import UUID, uuid4

import pytest
from sqlalchemy import delete, inspect, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models import AvailabilitySlot, Subject, Task, User


@pytest.fixture
def domain(db_session: Session) -> tuple[UUID, UUID, UUID, UUID]:
    user = User(
        email="student@example.test",
        password_hash="not-a-plain-text-password",
    )
    subject = Subject(name="Cálculo", teacher="Prof. Ada", user=user)
    task = Task(
        title="Lista de derivadas",
        description="Resolver os exercícios selecionados.",
        estimated_minutes=60,
        due_date=datetime(2026, 9, 10, 18, 0, tzinfo=timezone.utc),
        subject=subject,
    )
    availability = AvailabilitySlot(
        day_of_week=2,
        start_time=time(19, 0),
        end_time=time(21, 0),
        repeat_next_week=True,
        user=user,
    )

    db_session.add(user)
    db_session.commit()

    return user.id, subject.id, task.id, availability.id


def test_domain_models_persist_with_relationships(
    db_session: Session, domain: tuple[UUID, UUID, UUID, UUID]
) -> None:
    db_session.expunge_all()
    user = db_session.scalars(select(User).where(User.id == domain[0])).one()
    subject = user.subjects[0]
    task = subject.tasks[0]
    availability = user.availability_slots[0]

    assert isinstance(user.id, UUID)
    assert (subject.id, task.id, availability.id) == domain[1:]
    assert subject.user_id == user.id
    assert task.subject_id == subject.id
    assert availability.user_id == user.id
    assert user.subjects == [subject]
    assert subject.tasks == [task]
    assert user.availability_slots == [availability]
    assert availability.start_time == time(19, 0)
    assert availability.end_time == time(21, 0)
    assert task.is_completed is False
    assert user.created_at is not None
    assert user.updated_at is not None


def test_domain_foreign_keys_are_declared() -> None:
    subject_foreign_keys = inspect(Subject).local_table.foreign_keys
    task_foreign_keys = inspect(Task).local_table.foreign_keys
    availability_foreign_keys = inspect(AvailabilitySlot).local_table.foreign_keys

    assert {key.target_fullname for key in subject_foreign_keys} == {"users.id"}
    assert {key.target_fullname for key in task_foreign_keys} == {"subjects.id"}
    assert {key.target_fullname for key in availability_foreign_keys} == {"users.id"}


@pytest.mark.parametrize("model", [Subject, Task, AvailabilitySlot])
def test_database_rejects_missing_parent(db_session: Session, model) -> None:
    if model is Subject:
        entity = Subject(name="Test subject", user_id=uuid4())
    elif model is Task:
        entity = Task(
            subject_id=uuid4(),
            title="Test task",
            estimated_minutes=30,
            due_date=datetime(2026, 9, 10, tzinfo=timezone.utc),
        )
    else:
        entity = AvailabilitySlot(
            user_id=uuid4(), day_of_week=1, start_time=time(9), end_time=time(10)
        )

    db_session.add(entity)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()


def test_email_must_be_unique(db_session: Session) -> None:
    db_session.add_all([
        User(email="duplicate@example.test", password_hash="test-hash-1"),
        User(email="duplicate@example.test", password_hash="test-hash-2"),
    ])
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()


def test_user_deletion_cascades_in_database(
    db_session: Session, domain: tuple[UUID, UUID, UUID, UUID]
) -> None:
    # Bulk SQL bypasses ORM relationship cascades, exercising the foreign keys.
    db_session.execute(delete(User).where(User.id == domain[0]))
    db_session.commit()
    db_session.expunge_all()

    for model in (User, Subject, Task, AvailabilitySlot):
        assert db_session.scalars(select(model)).all() == []
