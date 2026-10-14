# LLM Gateway Proxy

An OpenAI-compatible gateway in front of Google AI Studio (Gemini), built on
[LiteLLM](https://docs.litellm.ai/docs/simple_proxy). Point any OpenAI SDK at it
and talk to Gemini models with automatic fallbacks and retries.

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env   # then fill in both keys
```

| Variable | Purpose |
| --- | --- |
| `GOOGLE_API_KEY` | Google AI Studio key — https://aistudio.google.com/apikey |
| `LITELLM_MASTER_KEY` | Bearer token clients must send. Must start with `sk-`; generate one with `openssl rand -hex 32`. The proxy refuses to start without it. |

## Run

```bash
./start.sh
```

`start.sh` strips whitespace from `GOOGLE_API_KEY` and `LITELLM_MASTER_KEY`
before launching LiteLLM, then execs `litellm --config config.yaml`. Set `PORT`
to override the default of 4000.

Do not start `litellm` directly in a deployment. A key pasted into a hosting
dashboard easily picks up a trailing newline, and LiteLLM passes the value
straight into the outbound `x-goog-api-key` header, where aiohttp rejects it:

```
ValueError: Forbidden control character detected in headers.
```

Every request then fails with a 500 and nothing is ever sent to Google, so the
logs show a Python traceback and no upstream error at all.

## Use

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "gemini-flash", "messages": [{"role": "user", "content": "hi"}]}'
```

With the OpenAI SDK:

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:4000/v1", api_key="<LITELLM_MASTER_KEY>")
client.chat.completions.create(
    model="gemini-flash",
    messages=[{"role": "user", "content": "hi"}],
)
```

## Models

Exposed names (see `config.yaml`):

- **Chat** — `gemini-flash`, `gemini-flash-lite`, `gemini-pro`, `gemini-2.5-flash`, `gemini-2.5-pro`
- **Embeddings** — `gemini-embedding`

`gemini-pro`, `gemini-flash` and `gemini-flash-lite` fall back to the stable 2.5
tier if the preview model fails.

## Endpoints

- `GET /health/liveliness` — unauthenticated liveness probe
- `GET /v1/models` — list the configured model names
- `POST /v1/chat/completions`, `POST /v1/embeddings` — OpenAI-compatible

## Deployment

Deployed on Railway as `LLMGateway-Proxy`, built from `main` with Railpack.
`railway.json` pins the start command to `bash start.sh`; set `GOOGLE_API_KEY`
and `LITELLM_MASTER_KEY` as service variables there.

Never commit `.env` — it is gitignored, and `.env.example` documents the keys instead.
# LLMGateway-Proxy
