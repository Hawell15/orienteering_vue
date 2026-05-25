<template>
    <div class="home-page">
        <div class="home-hero">
            <TopoBackdrop />
            <div class="home-hero-inner">
                <span class="home-eyebrow">🧭 Federația Sportului de Orientare</span>
                <h1 class="home-title">Baza de date a orientării sportive</h1>
                <p class="home-subtitle">Sportivi, cluburi, competiții și rezultate — toate într-un singur loc.</p>
            </div>
        </div>

        <div class="home-stats">
            <a class="stat-link-card" href="/runners">
                <span class="stat-link-icon">👤</span>
                <span class="stat-link-meta">
                    <span class="stat-link-label">Sportivi</span>
                    <span class="stat-link-value">{{ countData.runners_count ?? '—' }}</span>
                </span>
                <span class="stat-link-arrow">→</span>
            </a>
            <a class="stat-link-card" href="/clubs">
                <span class="stat-link-icon">🏛</span>
                <span class="stat-link-meta">
                    <span class="stat-link-label">Cluburi</span>
                    <span class="stat-link-value">{{ countData.clubs_count ?? '—' }}</span>
                </span>
                <span class="stat-link-arrow">→</span>
            </a>
            <a class="stat-link-card" href="/results">
                <span class="stat-link-icon">🏅</span>
                <span class="stat-link-meta">
                    <span class="stat-link-label">Rezultate</span>
                    <span class="stat-link-value">{{ countData.results_count ?? '—' }}</span>
                </span>
                <span class="stat-link-arrow">→</span>
            </a>
            <a class="stat-link-card" href="/competitions">
                <span class="stat-link-icon">🏆</span>
                <span class="stat-link-meta">
                    <span class="stat-link-label">Competiții</span>
                    <span class="stat-link-value">{{ countData.competitions_count ?? '—' }}</span>
                </span>
                <span class="stat-link-arrow">→</span>
            </a>
        </div>

        <div class="home-section">
            <div class="home-section-head">
                <div>
                    <span class="home-section-eyebrow">📅 Recente</span>
                    <h2 class="home-section-title">Ultimele 10 competiții</h2>
                </div>
                <a class="home-section-link" href="/competitions">Vezi toate →</a>
            </div>
            <div class="table-card">
                <div class="table-scroll">
                    <CompetitionTable :elements="competitionData" @order="() => {}"></CompetitionTable>
                </div>
                <div v-if="competitionData.length === 0" class="empty-state">
                    <div class="empty-state-icon">🔍</div>
                    <div>Nu există competiții încă.</div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from '@/axios'
import CompetitionTable from '../Competition/Table.vue'
import TopoBackdrop from '../shared/TopoBackdrop.vue'

const competitionData = ref([])
const countData = ref({})

onMounted(() => {
    getCountData();
    getCompetitionData();
})

async function getCountData() {
    const res = await axios.get('/home/index.json');
    countData.value = res.data;
}

async function getCompetitionData() {
    const params = {
        "sorting[sort_by]": "date",
        "sorting[direction]": "desc",
        "limit": 10
    }

    const res = await axios.get('/competitions.json', { params: params });
    competitionData.value = res.data;
}
</script>

<style scoped src="../shared/index.css"></style>

<style scoped>
.home-page {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    color: #1c2a1f;
    padding-bottom: 3rem;
}

.home-hero {
    position: relative;
    background:
        radial-gradient(circle at 80% 20%, rgba(251, 191, 36, 0.22), transparent 45%),
        linear-gradient(135deg, #14532d 0%, #1f5f3a 50%, #2d7a4c 100%);
    color: white;
    border-radius: 20px;
    padding: 3rem 2.4rem 3.4rem;
    margin-top: 1rem;
    box-shadow: 0 20px 50px -20px rgba(20, 83, 45, 0.55);
    overflow: hidden;
}

.home-hero-inner {
    position: relative;
    z-index: 1;
    max-width: 760px;
}

.home-eyebrow {
    display: inline-block;
    text-transform: uppercase;
    font-size: 0.78rem;
    letter-spacing: 2.5px;
    color: #fde68a;
    font-weight: 700;
    margin-bottom: 0.8rem;
}

.home-title {
    font-size: 2.6rem;
    font-weight: 800;
    line-height: 1.1;
    margin: 0 0 0.7rem 0;
    text-shadow: 0 2px 14px rgba(0, 0, 0, 0.25);
    letter-spacing: -0.01em;
}

.home-subtitle {
    font-size: 1.1rem;
    color: rgba(255, 255, 255, 0.88);
    margin: 0;
    max-width: 600px;
}

.home-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 1rem;
    margin-top: -2rem;
    margin-left: 1rem;
    margin-right: 1rem;
    position: relative;
    z-index: 2;
}

.stat-link-card {
    display: flex;
    align-items: center;
    gap: 0.8rem;
    background: white;
    border: 1px solid #d6e4d8;
    border-top: 3px solid #1f5f3a;
    border-radius: 14px;
    padding: 1.1rem 1.2rem;
    box-shadow: 0 4px 20px -6px rgba(20, 83, 45, 0.18);
    text-decoration: none;
    color: inherit;
    transition: transform 0.15s, box-shadow 0.15s, border-top-color 0.15s;
}
.stat-link-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 10px 28px -10px rgba(20, 83, 45, 0.3);
    border-top-color: #c2410c;
    color: inherit;
}

.stat-link-icon {
    font-size: 2rem;
    line-height: 1;
}

.stat-link-meta {
    display: flex;
    flex-direction: column;
    gap: 0.15rem;
    flex: 1;
}
.stat-link-label {
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 1px;
    color: #4f6b54;
    font-weight: 700;
}
.stat-link-value {
    font-size: 1.6rem;
    font-weight: 800;
    color: #14532d;
    font-variant-numeric: tabular-nums;
    line-height: 1.1;
}

.stat-link-arrow {
    color: #c2410c;
    font-weight: 800;
    font-size: 1.2rem;
    opacity: 0.5;
    transition: opacity 0.15s, transform 0.15s;
}
.stat-link-card:hover .stat-link-arrow {
    opacity: 1;
    transform: translateX(2px);
}

.home-section {
    margin-top: 2.5rem;
}

.home-section-head {
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    margin-bottom: 0.9rem;
    padding-bottom: 0.6rem;
    border-bottom: 1px solid #d6e4d8;
    gap: 1rem;
    flex-wrap: wrap;
}
.home-section-eyebrow {
    font-size: 0.72rem;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: #4f6b54;
    font-weight: 700;
    display: block;
    margin-bottom: 0.2rem;
}
.home-section-title {
    font-size: 1.5rem;
    font-weight: 800;
    color: #14532d;
    margin: 0;
    line-height: 1.2;
}
.home-section-link {
    color: #c2410c;
    text-decoration: none;
    font-weight: 700;
    font-size: 0.9rem;
    white-space: nowrap;
}
.home-section-link:hover { text-decoration: underline; }
</style>
