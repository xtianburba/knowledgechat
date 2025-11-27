module.exports = {
  apps: [
    {
      name: 'osac-backend',
      script: './backend/venv/bin/python',
      args: '-m uvicorn main:app --host 0.0.0.0 --port 8001 --workers 2',
      cwd: '/opt/osac-knowledge-bot/backend',
      interpreter: 'none',
      env: {
        NODE_ENV: 'production',
        PYTHONUNBUFFERED: '1'
      },
      error_file: '/opt/osac-knowledge-bot/backend/logs/backend-error.log',
      out_file: '/opt/osac-knowledge-bot/backend/logs/backend-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '500M',
      instances: 1,
      exec_mode: 'fork'
    },
    {
      name: 'osac-frontend',
      script: 'serve',
      args: '-s build -l 3001',
      cwd: '/opt/osac-knowledge-bot/frontend',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      error_file: '/opt/osac-knowledge-bot/frontend/logs/frontend-error.log',
      out_file: '/opt/osac-knowledge-bot/frontend/logs/frontend-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '300M'
    }
  ]
};

