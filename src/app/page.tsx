import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-8">
      <main className="flex flex-col gap-8 items-center max-w-2xl">
        <h1 className="text-4xl font-bold text-center">
          Next.js + Postgres + Docker Boilerplate
        </h1>
        
        <p className="text-center text-lg">
          A modern, production-ready boilerplate with Next.js, PostgreSQL, Docker, and Drizzle ORM.
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 w-full mt-8">
          <div className="p-6 border rounded-lg">
            <h2 className="text-xl font-semibold mb-2">⚡ Next.js 16</h2>
            <p className="text-sm">
              Latest version with App Router, Server Components, and more.
            </p>
          </div>

          <div className="p-6 border rounded-lg">
            <h2 className="text-xl font-semibold mb-2">🐘 PostgreSQL</h2>
            <p className="text-sm">
              Powerful, open-source relational database with Docker setup.
            </p>
          </div>

          <div className="p-6 border rounded-lg">
            <h2 className="text-xl font-semibold mb-2">🗄️ Drizzle ORM</h2>
            <p className="text-sm">
              TypeScript ORM with automatic migrations and type safety.
            </p>
          </div>

          <div className="p-6 border rounded-lg">
            <h2 className="text-xl font-semibold mb-2">🐳 Docker</h2>
            <p className="text-sm">
              Easy deployment with Docker Compose configuration.
            </p>
          </div>
        </div>

        <div className="flex gap-4 mt-8">
          <Link
            href="/api/health"
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
          >
            Check API Health
          </Link>
        </div>
      </main>
    </div>
  );
}
