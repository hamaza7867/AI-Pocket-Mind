/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        neonCyan: "#00f3ff",
        neonPurple: "#bd00ff",
        darkBg: "#0f0f1a",
        glass: "rgba(255, 255, 255, 0.05)",
      },
    },
  },
  plugins: [],
}
