<template>
    <header class="forest-navbar">
        <div class="forest-navbar-inner">
            <a class="brand" href="/">
                <img class="brand-logo" :src="logo" alt="FOS" />
                <span class="brand-text">
                    <span class="brand-name">FOS</span>
                    <span class="brand-sub">Orientare sportivă</span>
                </span>
            </a>

            <button class="nav-toggler" type="button" @click="open = !open" :aria-expanded="open" aria-label="Toggle navigation">
                <span class="bar"></span><span class="bar"></span><span class="bar"></span>
            </button>

            <nav class="nav-links" :class="{ open }">
                <a v-for="link in links" :key="link.href" :href="link.href"
                    class="nav-link" :class="{ active: isActive(link.href) }">
                    <span class="nav-icon">{{ link.icon }}</span>
                    <span>{{ link.label }}</span>
                </a>
            </nav>
        </div>
    </header>
</template>

<script setup>
import { ref, computed } from 'vue'
import logo from '@/images/logo_fos.png'

const open = ref(false)
const currentPath = ref(typeof window !== 'undefined' ? window.location.pathname : '/')

const links = [
    { href: '/competitions', label: 'Competiții', icon: '🏆' },
    { href: '/runners',      label: 'Sportivi',   icon: '👤' },
    { href: '/clubs',        label: 'Cluburi',    icon: '🏛' },
    { href: '/groups',       label: 'Grupe',      icon: '🏃' },
    { href: '/results',      label: 'Rezultate',  icon: '🏅' },
    { href: '/memberships',  label: 'Afilieri',   icon: '🪪' },
    { href: '/categories',   label: 'Categorii',  icon: '🎖' }
]

function isActive(href) {
    if (href === '/') return currentPath.value === '/'
    return currentPath.value.startsWith(href)
}
</script>

<style scoped>
.forest-navbar {
    background:
        radial-gradient(circle at 90% 0%, rgba(251, 191, 36, 0.18), transparent 50%),
        linear-gradient(90deg, #14532d 0%, #1f5f3a 60%, #2d7a4c 100%);
    color: white;
    box-shadow: 0 4px 20px -8px rgba(20, 83, 45, 0.5);
    position: relative;
}

.forest-navbar-inner {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0.7rem 1.3rem;
    display: flex;
    align-items: center;
    gap: 1rem;
    flex-wrap: wrap;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}

.brand {
    display: flex;
    align-items: center;
    gap: 0.7rem;
    color: white;
    text-decoration: none;
    margin-right: 1.2rem;
}
.brand-logo { height: 36px; width: auto; }
.brand-text { display: flex; flex-direction: column; line-height: 1.05; }
.brand-name {
    font-weight: 800;
    font-size: 1.15rem;
    letter-spacing: 0.5px;
    color: white;
}
.brand-sub {
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: #fde68a;
    font-weight: 600;
}

.nav-toggler {
    display: none;
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.18);
    border-radius: 8px;
    padding: 0.45rem 0.6rem;
    cursor: pointer;
    margin-left: auto;
    flex-direction: column;
    gap: 4px;
}
.nav-toggler .bar {
    width: 22px;
    height: 2px;
    background: white;
    border-radius: 2px;
}

.nav-links {
    display: flex;
    align-items: center;
    gap: 0.2rem;
    flex-wrap: wrap;
    margin-left: auto;
}

.nav-link {
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
    color: rgba(255, 255, 255, 0.85);
    text-decoration: none;
    padding: 0.42rem 0.85rem;
    border-radius: 8px;
    font-size: 0.9rem;
    font-weight: 600;
    transition: all 0.12s;
    border: 1px solid transparent;
    white-space: nowrap;
}
.nav-link:hover {
    background: rgba(255, 255, 255, 0.10);
    color: white;
}
.nav-link.active {
    background: rgba(251, 191, 36, 0.22);
    color: #fde68a;
    border-color: rgba(251, 191, 36, 0.35);
}
.nav-icon { font-size: 0.95rem; }

@media (max-width: 900px) {
    .nav-toggler { display: inline-flex; }
    .nav-links {
        flex-basis: 100%;
        flex-direction: column;
        align-items: stretch;
        margin: 0.6rem 0 0 0;
        gap: 0.25rem;
        max-height: 0;
        overflow: hidden;
        transition: max-height 0.22s ease;
    }
    .nav-links.open { max-height: 600px; }
    .nav-link { padding: 0.55rem 0.85rem; }
}
</style>
