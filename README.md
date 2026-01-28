# Next.js + PostgreSQL + Docker Boilerplate

A modern, production-ready boilerplate featuring Next.js 16, PostgreSQL, Docker, and Drizzle ORM with TypeScript support.

## 🚀 Features

- **Next.js 16** - Latest version with App Router and Server Components
- **TypeScript** - Full type safety throughout the application
- **PostgreSQL** - Powerful relational database
- **Docker Compose** - Easy local development setup
- **Drizzle ORM** - Type-safe database operations with automatic migrations
- **Tailwind CSS** - Utility-first CSS framework
- **ESLint** - Code linting and formatting

## 📋 Prerequisites

- Node.js 18+ and npm
- Docker and Docker Compose
- Git

## 🛠️ Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/munichdeveloper/boilerplate-nextjs-postgres-docker.git
cd boilerplate-nextjs-postgres-docker
```

### 2. Install dependencies

```bash
npm install
```

### 3. Set up environment variables

Copy the example environment file:

```bash
cp .env.example .env
```

The default configuration in `.env.example` should work for local development.

### 4. Start the PostgreSQL database

```bash
docker-compose up -d
```

This will start a PostgreSQL 16 instance on port 5432.

### 5. Run database migrations

Generate and apply the initial database schema:

```bash
npm run db:push
```

### 6. Start the development server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser to see the application.

## 📁 Project Structure

```
.
├── src/
│   ├── app/                 # Next.js App Router
│   │   ├── api/            # API routes
│   │   │   └── health/     # Health check endpoint
│   │   ├── layout.tsx      # Root layout
│   │   ├── page.tsx        # Home page
│   │   └── globals.css     # Global styles
│   └── db/
│       ├── index.ts        # Database connection
│       └── schema.ts       # Database schema
├── drizzle/                # Generated migrations (gitignored)
├── docker-compose.yml      # Docker Compose configuration
├── drizzle.config.ts       # Drizzle ORM configuration
├── next.config.ts          # Next.js configuration
├── tailwind.config.ts      # Tailwind CSS configuration
└── tsconfig.json           # TypeScript configuration
```

## 🗄️ Database

### Schema

The boilerplate includes example schemas for `users` and `posts`:

- **users**: id, name, email, createdAt, updatedAt
- **posts**: id, title, content, published, authorId, createdAt, updatedAt

### Drizzle Commands

- `npm run db:generate` - Generate SQL migrations from schema changes
- `npm run db:migrate` - Apply migrations to the database
- `npm run db:push` - Push schema changes directly (for development)
- `npm run db:studio` - Open Drizzle Studio (database GUI)

### Accessing the Database

The PostgreSQL database is accessible at:
- **Host**: localhost
- **Port**: 5432
- **Database**: nextjs_db
- **User**: postgres
- **Password**: postgres

## 🐳 Docker

### Start containers

```bash
docker-compose up -d
```

### Stop containers

```bash
docker-compose down
```

### Stop containers and remove data

```bash
docker-compose down -v
```

## 🧪 API Endpoints

### Health Check

`GET /api/health`

Returns the health status of the application and database connection.

Example response:
```json
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2026-01-28T18:00:00.000Z"
}
```

## 📦 Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint
- `npm run db:generate` - Generate migrations
- `npm run db:migrate` - Run migrations
- `npm run db:push` - Push schema to database
- `npm run db:studio` - Open Drizzle Studio

## 🔒 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:postgres@localhost:5432/nextjs_db` |
| `NEXT_PUBLIC_APP_URL` | Public app URL | `http://localhost:3000` |

## 🚢 Production Deployment

1. Build the application:
```bash
npm run build
```

2. Set production environment variables in your hosting platform

3. Ensure your PostgreSQL database is accessible

4. Run migrations:
```bash
npm run db:migrate
```

5. Start the production server:
```bash
npm start
```

## 📝 License

MIT

## 👤 Author

Munich Developer

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
