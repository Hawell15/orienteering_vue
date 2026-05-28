<template>
    <div v-if="isAdmin" class="admin-bar">
        <div class="admin-bar-inner">
            <span class="admin-bar-eyebrow">⚙ Panou administrator</span>

            <div class="admin-bar-spacer"></div>

            <div class="admin-menu-wrapper" ref="menuWrapper">
                <button type="button" class="admin-menu-trigger" :class="{ open: menuOpen }"
                    :aria-expanded="menuOpen" aria-haspopup="true" @click="menuOpen = !menuOpen">
                    <span class="admin-menu-plus">＋</span>
                    <span class="admin-menu-label">Adaugă</span>
                    <span class="admin-menu-caret">▾</span>
                </button>

                <div v-if="menuOpen" class="admin-dropdown" role="menu">
                    <a v-for="item in items" :key="item.href" :href="item.href" role="menuitem"
                        class="admin-dropdown-item" @click="menuOpen = false">
                        <span class="admin-dropdown-icon">{{ item.icon }}</span>
                        <span>{{ item.label }}</span>
                    </a>
                    <div class="admin-dropdown-divider"></div>
                    <a :href="fileImportPath" role="menuitem" class="admin-dropdown-item file"
                        @click="menuOpen = false">
                        <span class="admin-dropdown-icon">📂</span>
                        <span>Adaugă din Fișier</span>
                    </a>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { isAdmin } from '@/currentUser'

const menuOpen = ref(false)
const menuWrapper = ref(null)
const fileImportPath = '/parser/file_results'

const items = [
    { href: '/competitions/new', label: 'Adaugă competiție', icon: '🏆' },
    { href: '/runners/new',      label: 'Adaugă sportiv',    icon: '👤' },
    { href: '/clubs/new',        label: 'Adaugă club',       icon: '🏛' },
    { href: '/groups/new',       label: 'Adaugă grupă',      icon: '🏃' },
    { href: '/results/new',      label: 'Adaugă rezultat',   icon: '🏅' },
    { href: '/memberships/new',  label: 'Adaugă afiliere',   icon: '🪪' }
]

function handleDocumentClick(event) {
    if (!menuOpen.value) return
    if (menuWrapper.value && !menuWrapper.value.contains(event.target)) {
        menuOpen.value = false
    }
}

function handleEscape(event) {
    if (event.key === 'Escape') menuOpen.value = false
}

onMounted(() => {
    document.addEventListener('click', handleDocumentClick)
    document.addEventListener('keydown', handleEscape)
})

onBeforeUnmount(() => {
    document.removeEventListener('click', handleDocumentClick)
    document.removeEventListener('keydown', handleEscape)
})
</script>

<style scoped>
.admin-bar {
    background:
        linear-gradient(90deg, #fffbea 0%, #fef3c7 100%);
    border-bottom: 1px solid #fde68a;
    box-shadow: 0 2px 8px -4px rgba(146, 64, 14, 0.18);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    margin: -1.25rem -1rem 1.25rem -1rem;
}

.admin-bar-inner {
    display: flex;
    align-items: center;
    gap: 0.9rem;
    padding: 0.55rem 1.2rem;
    max-width: 1400px;
    margin: 0 auto;
}

.admin-bar-eyebrow {
    color: #92400e;
    font-size: 0.72rem;
    font-weight: 700;
    letter-spacing: 1.5px;
    text-transform: uppercase;
}

.admin-bar-spacer { flex: 1; }

.admin-menu-wrapper { position: relative; }

.admin-menu-trigger {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    background: linear-gradient(135deg, #14532d, #2d7a4c);
    color: white;
    border: 1px solid #14532d;
    padding: 0.5rem 1rem;
    border-radius: 9px;
    cursor: pointer;
    font-family: inherit;
    font-size: 0.88rem;
    font-weight: 600;
    letter-spacing: 0.2px;
    box-shadow: 0 2px 6px -2px rgba(20, 83, 45, 0.4);
    transition: transform 0.05s, box-shadow 0.12s, background 0.12s;
}
.admin-menu-trigger:hover {
    background: linear-gradient(135deg, #0f3a1e, #1f5f3a);
    box-shadow: 0 4px 10px -2px rgba(20, 83, 45, 0.5);
}
.admin-menu-trigger:active { transform: translateY(1px); }
.admin-menu-trigger.open {
    background: linear-gradient(135deg, #0f3a1e, #14532d);
    box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.2);
}

.admin-menu-plus { font-size: 1.1rem; line-height: 1; }
.admin-menu-label { white-space: nowrap; }
.admin-menu-caret {
    font-size: 0.65rem;
    transition: transform 0.18s ease;
}
.admin-menu-trigger.open .admin-menu-caret { transform: rotate(180deg); }

.admin-dropdown {
    position: absolute;
    top: calc(100% + 0.55rem);
    right: 0;
    min-width: 240px;
    background: white;
    color: #1f2937;
    border-radius: 12px;
    box-shadow:
        0 14px 32px -8px rgba(20, 83, 45, 0.3),
        0 4px 12px -4px rgba(0, 0, 0, 0.16);
    padding: 0.45rem;
    display: flex;
    flex-direction: column;
    gap: 0.12rem;
    z-index: 200;
    animation: admin-dropdown-in 0.14s ease-out;
}

@keyframes admin-dropdown-in {
    from { opacity: 0; transform: translateY(-4px); }
    to   { opacity: 1; transform: translateY(0); }
}

.admin-dropdown::before {
    content: "";
    position: absolute;
    top: -6px;
    right: 22px;
    width: 12px;
    height: 12px;
    background: white;
    transform: rotate(45deg);
    box-shadow: -1px -1px 1px rgba(20, 83, 45, 0.06);
}

.admin-dropdown-item {
    display: flex;
    align-items: center;
    gap: 0.65rem;
    padding: 0.55rem 0.75rem;
    border-radius: 8px;
    color: #1f2937;
    text-decoration: none;
    font-size: 0.9rem;
    font-weight: 600;
    transition: background-color 0.1s, color 0.1s;
    white-space: nowrap;
}
.admin-dropdown-item:hover {
    background: #f0fdf4;
    color: #14532d;
}
.admin-dropdown-item.file:hover {
    background: #fffbea;
    color: #92400e;
}

.admin-dropdown-icon { font-size: 1rem; width: 1.2rem; text-align: center; }

.admin-dropdown-divider {
    height: 1px;
    background: #e5e7eb;
    margin: 0.35rem 0.4rem;
}

@media (max-width: 600px) {
    .admin-bar-eyebrow { font-size: 0.65rem; letter-spacing: 1px; }
    .admin-menu-label { display: none; }
    .admin-bar-inner { padding: 0.55rem 0.9rem; }
    .admin-dropdown { min-width: 220px; right: -0.5rem; }
}
</style>
