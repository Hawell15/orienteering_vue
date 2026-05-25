<template>
    <div class="index-page">
        <div class="index-hero">
            <TopoBackdrop />
            <div class="index-hero-inner">
                <div class="index-title-block">
                    <span class="index-eyebrow">🏆 Clasament</span>
                    <h1 class="index-title">Clasament Național (ECN)</h1>
                </div>
                <span class="index-count">{{ data.length }}</span>
            </div>
        </div>

        <div class="filter-panel">
            <div class="filter-panel-head">
                <span class="filter-panel-title">⚙ Filtre</span>
                <button class="reset-btn" @click="resetFilters">Resetează</button>
            </div>
            <div class="filter-grid">
                <div class="filter-item">
                    <label class="label-filter">Gen</label>
                    <div class="checkbox-row">
                        <label class="checkbox-pill" :class="{ checked: filters.gender === 'M' }">
                            <input type="radio" name="gender" value="M" v-model="filters.gender" /> Masculin
                        </label>
                        <label class="checkbox-pill" :class="{ checked: filters.gender === 'W' }">
                            <input type="radio" name="gender" value="W" v-model="filters.gender" /> Feminin
                        </label>
                    </div>
                </div>
                <div class="filter-item">
                    <label for="date" class="label-filter">Data</label>
                    <input id="date" type="date" v-model="filters.date" class="custom-input" />
                </div>
            </div>
        </div>

        <div v-if="podium.length" class="ecn-podium">
            <div v-for="(p, i) in podium" :key="p.id" class="ecn-podium-card" :class="`place-${i + 1}`">
                <div class="medal">{{ ['🥇', '🥈', '🥉'][i] }}</div>
                <div class="ecn-podium-name"><a :href="`/runners/${p.id}`">{{ p.runner_name }} {{ p.surname }}({{ p.yob }})</a></div>
                <div class="ecn-podium-club"><a v-if="p.club" :href="`/clubs/${p.club.id}`">{{ p.club.club_name }}</a></div>
                <div class="ecn-podium-points">{{ formatPoints(p.total_points) }} <span class="ecn-podium-points-label">p</span></div>
                <div class="ecn-podium-meta">{{ p.ecn_results_count }} rezultate</div>
            </div>
        </div>

        <div class="table-card">
            <div class="table-scroll">
                <table class="forest-table">
                    <thead>
                        <tr>
                            <th>Locul</th>
                            <th>Sportiv</th>
                            <th>Club</th>
                            <th>An</th>
                            <th>Punctaj</th>
                            <th>Rezultate</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        <template v-for="row in data" :key="row.id">
                            <tr class="ranking-row" :class="{ expanded: expandedId === row.id }" @click="toggleRow(row)">
                                <td>{{ row.place }}</td>
                                <td><a :href="`/runners/${row.id}`" @click.stop>{{ row.runner_name }} {{ row.surname }}</a></td>
                                <td><a v-if="row.club" :href="`/clubs/${row.club.id}`" @click.stop>{{ row.club.club_name }}</a></td>
                                <td>{{ row.yob }}</td>
                                <td><span class="cell-badge ecn">{{ formatPoints(row.total_points) }}</span></td>
                                <td>{{ row.ecn_results_count }}</td>
                                <td class="caret-cell">
                                    <span class="caret">▾</span>
                                </td>
                            </tr>
                            <tr v-if="expandedId === row.id" class="expand-row">
                                <td colspan="7" class="expand-cell">
                                    <div v-if="runnerLoading[row.id]" class="expand-loading">
                                        ⏳ Se încarcă rezultatele…
                                    </div>
                                    <div v-else-if="runnerResults[row.id]?.results?.length" class="expand-body">
                                        <div class="expand-legend">
                                            <span class="legend-dot threshold"></span>
                                            <span>Cele mai bune {{ runnerResults[row.id].limit_number }} rezultate contează.
                                                Rezultate sub <b>{{ formatPoints(runnerResults[row.id].min_limit_points) }}</b> puncte sunt excluse.</span>
                                        </div>
                                        <table class="inner-table">
                                            <thead>
                                                <tr>
                                                    <th>Data</th>
                                                    <th>Competiția</th>
                                                    <th>Grupa</th>
                                                    <th>Locul</th>
                                                    <th>Puncte</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="r in runnerResults[row.id].results" :key="r.id"
                                                    :class="{ excluded: r.ecn_points < runnerResults[row.id].min_limit_points }">
                                                    <td>{{ formatDate(r.date) }}</td>
                                                    <td><a :href="`/competitions/${r.group?.competition?.id}`">{{ r.group?.competition?.competition_name }}</a></td>
                                                    <td>{{ r.group?.group_name }}</td>
                                                    <td>{{ r.place }}</td>
                                                    <td>{{ r.ecn_points }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                    <div v-else class="expand-empty">Nu există rezultate.</div>
                                </td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>
            <div v-if="!loading && data.length === 0" class="empty-state">
                <div class="empty-state-icon">🔍</div>
                <div>Nu există rezultate pentru filtrele selectate.</div>
            </div>
            <div v-if="loading" class="empty-state">
                <div class="empty-state-icon">⏳</div>
                <div>Se încarcă clasamentul…</div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { reactive, ref, computed, onMounted, watch } from 'vue'
import axios from '@/axios'
import TopoBackdrop from '../shared/TopoBackdrop.vue'

const today = new Date().toISOString().slice(0, 10)

const DEFAULT_FILTERS = {
    gender: 'M',
    date: today
}

const filters = reactive({ ...DEFAULT_FILTERS })
const data = ref([])
const loading = ref(false)

const expandedId = ref(null)
const runnerResults = reactive({})
const runnerLoading = reactive({})

const podium = computed(() => data.value.slice(0, 3))

let debounceTimeout = null

watch(filters, () => {
    clearTimeout(debounceTimeout)
    debounceTimeout = setTimeout(() => {
        expandedId.value = null
        Object.keys(runnerResults).forEach(k => delete runnerResults[k])
        getData()
    }, 300)
}, { deep: true })

onMounted(getData)

async function getData() {
    loading.value = true
    try {
        const res = await axios.get('/competitions/ecn_ranking.json', { params: { ...filters } })
        data.value = res.data
    } catch (e) {
        console.error('Ranking fetch failed:', e)
        data.value = []
    } finally {
        loading.value = false
    }
}

async function toggleRow(row) {
    if (expandedId.value === row.id) {
        expandedId.value = null
        return
    }
    expandedId.value = row.id

    if (runnerResults[row.id]) return

    runnerLoading[row.id] = true
    try {
        const res = await axios.get('/competitions/ecn_runner_results.json', {
            params: { runner_id: row.id, date: filters.date }
        })
        runnerResults[row.id] = res.data
    } catch (e) {
        console.error('Runner results fetch failed:', e)
        runnerResults[row.id] = { results: [], min_limit_points: 0, limit_number: 0 }
    } finally {
        runnerLoading[row.id] = false
    }
}

function resetFilters() {
    Object.assign(filters, DEFAULT_FILTERS)
}

function formatPoints(p) {
    if (p == null) return '0'
    return Number(p).toFixed(2)
}

function formatDate(d) {
    if (!d) return ''
    const [y, m, day] = d.split('-')
    return `${day}/${m}/${y}`
}
</script>

<style scoped src="../shared/index.css"></style>

<style scoped>
.ecn-podium {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1rem;
    margin-top: 1.2rem;
}
@media (max-width: 700px) {
    .ecn-podium { grid-template-columns: 1fr; }
}
.ecn-podium-card {
    background: white;
    border: 1px solid #d6e4d8;
    border-top: 4px solid #c2410c;
    border-radius: 16px;
    padding: 1.2rem;
    text-align: center;
    transition: transform 0.15s;
}
.ecn-podium-card:hover { transform: translateY(-2px); }
.ecn-podium-card.place-1 { background: linear-gradient(180deg, #fff7ed, #fed7aa); border-color: #fb923c; border-top-color: #c2410c; }
.ecn-podium-card.place-2 { background: linear-gradient(180deg, #fafaf9, #e7e5e4); border-color: #d6d3d1; border-top-color: #78716c; }
.ecn-podium-card.place-3 { background: linear-gradient(180deg, #fef3c7, #fde68a); border-color: #f59e0b; border-top-color: #b45309; }
.ecn-podium-card .medal { font-size: 2.2rem; }
.ecn-podium-name { font-weight: 700; font-size: 1.05rem; margin-top: 0.3rem; }
.ecn-podium-name a { color: inherit; text-decoration: none; }
.ecn-podium-name a:hover { text-decoration: underline; }
.ecn-podium-club { font-size: 0.85rem; color: #57534e; }
.ecn-podium-club a { color: inherit; text-decoration: none; }
.ecn-podium-club a:hover { text-decoration: underline; }
.ecn-podium-points {
    font-variant-numeric: tabular-nums;
    font-weight: 800;
    font-size: 1.6rem;
    margin-top: 0.5rem;
    color: #14532d;
}
.ecn-podium-points-label { font-size: 0.8rem; color: #4f6b54; font-weight: 600; }
.ecn-podium-meta { font-size: 0.78rem; color: #4f6b54; margin-top: 0.2rem; }

.ranking-row { cursor: pointer; transition: background 0.1s; }
.ranking-row:hover { background: #f1f5e8; }
.ranking-row.expanded { background: #f1f5e8; }
.caret-cell { width: 32px; text-align: center; }
.caret {
    display: inline-block;
    color: #4f6b54;
    transition: transform 0.2s;
    font-size: 0.85rem;
}
.ranking-row.expanded .caret { transform: rotate(180deg); color: #c2410c; }

.expand-row { background: #fafcf7; }
.expand-cell { padding: 0 !important; }

.expand-body { padding: 1rem 1.2rem 1.2rem; }
.expand-loading, .expand-empty { padding: 1.2rem; text-align: center; color: #4f6b54; }

.expand-legend {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.82rem;
    color: #4f6b54;
    margin-bottom: 0.7rem;
}
.legend-dot {
    display: inline-block;
    width: 12px;
    height: 12px;
    border-radius: 3px;
    background: #fee2e2;
    border: 1px solid #fca5a5;
}

.inner-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.88rem;
    background: white;
    border: 1px solid #d6e4d8;
    border-radius: 8px;
    overflow: hidden;
}
.inner-table thead { background: #f1f5e8; }
.inner-table thead th {
    text-align: left;
    color: #14532d;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1px;
    font-size: 0.7rem;
    padding: 0.5rem 0.7rem;
    border-bottom: 1px solid #d6e4d8;
}
.inner-table tbody td {
    padding: 0.4rem 0.7rem;
    border-bottom: 1px solid #f1f5e8;
    color: #1c2a1f;
}
.inner-table tbody tr:last-child td { border-bottom: none; }
.inner-table tbody tr.excluded td {
    background: #fee2e2;
    color: #7f1d1d;
}
.inner-table a { color: #c2410c; text-decoration: none; font-weight: 600; }
.inner-table a:hover { text-decoration: underline; }
</style>
