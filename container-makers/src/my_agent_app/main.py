import logging
from contextlib import asynccontextmanager

from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(level=logging.INFO)

from fastapi import FastAPI
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from starlette.exceptions import HTTPException as StarletteHTTPException

from my_agent_app.api.router import router as api_router
from my_agent_app.database import get_database_url
from my_agent_app.web.router import html_exception_handler
from my_agent_app.web.router import router as web_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # O engine nao conecta no startup: a conexao so e aberta no primeiro uso.
    # Assim a aplicacao sobe mesmo sem o PostgreSQL rodando.
    engine = create_async_engine(get_database_url())
    app.state.sessionmaker = async_sessionmaker(engine, expire_on_commit=False)

    yield

    await engine.dispose()


app = FastAPI(title="My Agent App", lifespan=lifespan)
app.include_router(api_router)
app.include_router(web_router)
app.add_exception_handler(StarletteHTTPException, html_exception_handler)
