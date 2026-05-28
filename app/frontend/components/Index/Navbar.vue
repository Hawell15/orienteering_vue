<template>
    <div>
        <button type="button" class="sidebar-mobile-toggle" :class="{ open: mobileOpen }"
            :aria-expanded="mobileOpen" aria-label="Toggle navigation"
            @click="mobileOpen = !mobileOpen">
            <span></span><span></span><span></span>
        </button>

        <div v-if="mobileOpen" class="sidebar-backdrop" @click="mobileOpen = false"></div>

        <aside class="forest-sidebar" :class="{ open: mobileOpen }">
            <a class="brand" href="/" @click="mobileOpen = false">
                <img class="brand-logo" :src="logo" alt="FOS" />
                <span class="brand-text">
                    <span class="brand-name">FOS</span>
                    <span class="brand-sub">Orientare sportivă</span>
                </span>
            </a>

            <nav class="sidebar-nav" role="navigation">
                <a v-for="link in links" :key="link.href" :href="link.href"
                    class="sidebar-link" :class="{ active: isActive(link.href) }"
                    @click="mobileOpen = false">
                    <span class="sidebar-icon">{{ link.icon }}</span>
                    <span class="sidebar-text">{{ link.label }}</span>
                </a>
            </nav>

            <div class="sidebar-auth">
                <div v-if="isSignedIn" class="sidebar-user">
                    <div class="sidebar-user-label">Conectat ca</div>
                    <div class="sidebar-user-email">{{ userEmail }}</div>
                    <button type="button" class="sidebar-auth-btn" @click="signOut">
                        <span class="sidebar-icon">⇥</span><span>Deconectare</span>
                    </button>
                </div>
                <a v-else :href="signInPath" class="sidebar-auth-btn">
                    <span class="sidebar-icon">⇤</span><span>Autentificare</span>
                </a>
            </div>
        </aside>
    </div>
</template>

<script setup>
import { ref } from 'vue'
import axios from '@/axios'
import logo from '@/images/logo_fos.png'
import { isSignedIn, userEmail, signInPath, signOutPath } from '@/currentUser'

async function signOut() {
    try {
        await axios.delete(signOutPath)
    } catch (e) {
        // Devise returns 204 or redirect; ignore errors here.
    }
    window.location.href = '/'
}

const mobileOpen = ref(false)
const currentPath = ref(typeof window !== 'undefined' ? window.location.pathname : '/')

const links = [
    { href: '/competitions',              label: 'Competiții', icon: '🏆' },
    { href: '/runners',                   label: 'Sportivi',   icon: '👤' },
    { href: '/clubs',                     label: 'Cluburi',    icon: '🏛' },
    { href: '/groups',                    label: 'Grupe',      icon: '🏃' },
    { href: '/results',                   label: 'Rezultate',  icon: '🏅' },
    { href: '/memberships',               label: 'Afilieri',   icon: '🪪' },
    { href: '/categories',                label: 'Categorii',  icon: '🎖' },
    { href: '/competitions/ecn_ranking',  label: 'Clasament',  icon: '🥇' }
]

function isActive(href) {
    if (href === '/') return currentPath.value === '/'
    if (!currentPath.value.startsWith(href)) return false
    return !links.some(other =>
        other.href !== href &&
        other.href.length > href.length &&
        other.href.startsWith(href) &&
        currentPath.value.startsWith(other.href)
    )
}
</script>

<style scoped>
.forest-sidebar {
    position: fixed;
    top: 0;
    left: 0;
    width: 240px;
    height: 100vh;
    background:
        radial-gradient(circle at 90% 0%, rgba(251, 191, 36, 0.18), transparent 50%),
        linear-gradient(180deg, #14532d 0%, #1f5f3a 60%, #2d7a4c 100%);
    color: white;
    box-shadow: 4px 0 20px -8px rgba(20, 83, 45, 0.5);
    display: flex;
    flex-direction: column;
    z-index: 100;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    overflow-y: auto;
}

.brand {
    display: flex;
    align-items: center;
    gap: 0.7rem;
    color: white;
    text-decoration: none;
    padding: 1.1rem 1.1rem 1rem 1.1rem;
    border-bottom: 1px solid rgba(255, 255, 255, 0.12);
}
.brand-logo { height: 40px; width: auto; }
.brand-text { display: flex; flex-direction: column; line-height: 1.05; }
.brand-name {
    font-weight: 800;
    font-size: 1.2rem;
    letter-spacing: 0.5px;
    color: white;
}
.brand-sub {
    font-size: 0.65rem;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: #fde68a;
    font-weight: 600;
}

.sidebar-nav {
    display: flex;
    flex-direction: column;
    gap: 0.18rem;
    padding: 0.85rem 0.6rem;
    flex: 1;
}

.sidebar-link {
    display: flex;
    align-items: center;
    gap: 0.7rem;
    color: rgba(255, 255, 255, 0.85);
    text-decoration: none;
    padding: 0.6rem 0.85rem;
    border-radius: 8px;
    font-size: 0.92rem;
    font-weight: 600;
    transition: background-color 0.12s, color 0.12s;
    border: 1px solid transparent;
    white-space: nowrap;
}
.sidebar-link:hover {
    background: rgba(255, 255, 255, 0.10);
    color: white;
}
.sidebar-link.active {
    background: rgba(251, 191, 36, 0.22);
    color: #fde68a;
    border-color: rgba(251, 191, 36, 0.35);
}
.sidebar-icon { font-size: 1rem; width: 1.2rem; text-align: center; }
.sidebar-text { letter-spacing: 0.2px; }

.sidebar-auth {
    border-top: 1px solid rgba(255, 255, 255, 0.12);
    padding: 0.9rem;
}

.sidebar-user {
    display: flex;
    flex-direction: column;
    gap: 0.45rem;
}
.sidebar-user-label {
    font-size: 0.65rem;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    color: rgba(255, 255, 255, 0.55);
    font-weight: 600;
}
.sidebar-user-email {
    color: #fde68a;
    font-size: 0.82rem;
    font-weight: 600;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.sidebar-auth-btn {
    display: flex;
    align-items: center;
    gap: 0.55rem;
    width: 100%;
    background: rgba(255, 255, 255, 0.08);
    border: 1px solid rgba(255, 255, 255, 0.22);
    color: white;
    padding: 0.55rem 0.85rem;
    border-radius: 8px;
    text-decoration: none;
    cursor: pointer;
    font-family: inherit;
    font-size: 0.85rem;
    font-weight: 600;
    transition: background-color 0.12s, border-color 0.12s;
}
.sidebar-auth-btn:hover {
    background: rgba(255, 255, 255, 0.16);
    border-color: rgba(255, 255, 255, 0.38);
    color: white;
}

.sidebar-mobile-toggle {
    display: none;
    position: fixed;
    top: 0.9rem;
    left: 0.9rem;
    z-index: 200;
    width: 42px;
    height: 42px;
    background: linear-gradient(135deg, #14532d, #2d7a4c);
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 10px;
    cursor: pointer;
    box-shadow: 0 4px 12px -3px rgba(20, 83, 45, 0.5);
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 4px;
}
.sidebar-mobile-toggle span {
    display: block;
    width: 20px;
    height: 2px;
    background: white;
    border-radius: 2px;
    transition: transform 0.18s ease, opacity 0.18s ease;
}
.sidebar-mobile-toggle.open span:nth-child(1) { transform: translateY(6px) rotate(45deg); }
.sidebar-mobile-toggle.open span:nth-child(2) { opacity: 0; }
.sidebar-mobile-toggle.open span:nth-child(3) { transform: translateY(-6px) rotate(-45deg); }

.sidebar-backdrop {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(15, 23, 42, 0.45);
    z-index: 90;
}

@media (max-width: 900px) {
    .sidebar-mobile-toggle { display: inline-flex; }
    .sidebar-backdrop { display: block; }
    .forest-sidebar {
        transform: translateX(-100%);
        transition: transform 0.22s ease;
    }
    .forest-sidebar.open { transform: translateX(0); }
}
</style>
