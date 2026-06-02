<template>
    <div class="show-page">
        <div class="hero">
            <TopoBackdrop />
            <div class="hero-inner">
                <div class="hero-top">
                    <div>
                        <div class="eyebrow">📜 Confirmări categorii</div>
                        <h1 class="title">{{ competition.competition_name }}</h1>
                        <div class="subtitle">
                            <span>{{ competition.distance_type }}</span>
                            <template v-if="competition.location">
                                <span class="dot">·</span>
                                <span>{{ competition.location }}<span v-if="competition.country">, {{ competition.country }}</span></span>
                            </template>
                            <template v-if="competition.date">
                                <span class="dot">·</span>
                                <span>{{ competition.date }}</span>
                            </template>
                        </div>
                    </div>
                    <div class="hero-actions">
                        <a class="btn btn-light" :href="`/competitions/${competitionId}`">← Înapoi la competiție</a>
                        <a class="btn btn-light" :href="`/competitions/${competitionId}.pdf?style=confirmations`">📄 PDF</a>
                    </div>
                </div>
            </div>
        </div>

        <div class="stat-cards">
            <div class="stat-card">
                <div class="stat-icon">📌</div>
                <div class="stat-label">Plafonate</div>
                <div class="stat-value">{{ data.capped?.length || 0 }}</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">⬆️</div>
                <div class="stat-label">Îmbunătățite</div>
                <div class="stat-value">{{ data.improved?.length || 0 }}</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">🔄</div>
                <div class="stat-label">Confirmate</div>
                <div class="stat-value">{{ data.extended?.length || 0 }}</div>
            </div>
            <div class="stat-card accent">
                <div class="stat-icon">∑</div>
                <div class="stat-label">Total</div>
                <div class="stat-value">{{ totalCount }}</div>
            </div>
        </div>

        <div class="filter-panel">
            <div class="filter-panel-head">
                <span class="filter-panel-title">⚙ Filtre</span>
                <button class="reset-btn" @click="resetFilters">Resetează</button>
            </div>
            <div class="filter-grid">
                <div class="filter-item">
                    <label class="label-filter">Caută</label>
                    <input type="text" v-model="filters.search" class="custom-input" placeholder="Nume, club sau FOS ID…" />
                </div>
                <div class="filter-item">
                    <label class="label-filter">Grupa</label>
                    <select v-model="filters.group_id" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="g in groupOptions" :key="g.id" :value="g.id">{{ g.name }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Secțiuni</label>
                    <div class="checkbox-row">
                        <label class="checkbox-pill" :class="{ checked: filters.sections.capped }">
                            <input type="checkbox" v-model="filters.sections.capped" /> 📌 Plafonate
                        </label>
                        <label class="checkbox-pill" :class="{ checked: filters.sections.improved }">
                            <input type="checkbox" v-model="filters.sections.improved" /> ⬆️ Îmbunătățite
                        </label>
                        <label class="checkbox-pill" :class="{ checked: filters.sections.extended }">
                            <input type="checkbox" v-model="filters.sections.extended" /> 🔄 Confirmate
                        </label>
                    </div>
                </div>
            </div>
        </div>

        <div v-for="sec in visibleSections" :key="sec.key" class="section">
            <div class="section-card">
                <div class="section-card-title">
                    {{ sec.title }}
                    <span class="count-pill">{{ sec.rows.length }}</span>
                </div>
                <div v-if="sec.subtitle" class="section-subtitle">{{ sec.subtitle }}</div>
                <div class="table-scroll">
                    <table class="forest-table">
                        <thead>
                            <tr>
                                <th>Sportiv</th>
                                <th>An</th>
                                <th>Club</th>
                                <th>Grupa</th>
                                <th>Cat. anterioară</th>
                                <th v-if="sec.key === 'capped'">Cat. plafonată</th>
                                <th>{{ sec.key === 'capped' ? 'Cat. îndeplinită *' : 'Cat. îndeplinită' }}</th>
                                <th>Timp</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="r in sec.rows" :key="r.id">
                                <td><a :href="`/runners/${r.runner_id}`">{{ r.full_name }}</a></td>
                                <td>{{ r.yob || '—' }}</td>
                                <td><a :href="`/clubs/${r.club_id}`">{{ r.club_name }}</a></td>
                                <td><a :href="`/groups/${r.group_id}`">{{ r.group_name }}</a></td>
                                <td>{{ r.runner_category_name || 'f/c' }}</td>
                                <td v-if="sec.key === 'capped'">{{ r.new_category_name }}</td>
                                <td>{{ sec.key === 'capped' ? (r.achievement || '—') : r.new_category_name }}</td>
                                <td>{{ formatTime(r.time) }}</td>
                            </tr>
                            <tr v-if="sec.rows.length === 0">
                                <td colspan="8" class="empty-row">Niciun rezultat în această secțiune (după filtre).</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <p v-if="sec.key === 'capped' && sec.rows.length" class="footnote">
                    * Categoria îndeplinită trebuie confirmată la Ministerul Educației și Cercetării al Republicii Moldova.
                </p>
            </div>
        </div>

        <div v-if="loaded && totalCount === 0" class="section">
            <div class="section-card empty-card">
                <div class="empty-state-icon">🔍</div>
                <div>Nicio confirmare pentru această competiție.</div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { reactive, ref, computed, onMounted } from 'vue'
import axios from '@/axios'
import TopoBackdrop from '../shared/TopoBackdrop.vue'

const competitionId = ref('')
const competition   = ref({})
const data          = ref({ capped: [], improved: [], extended: [] })
const loaded        = ref(false)

const filters = reactive({
    search:   '',
    group_id: 'all',
    sections: { capped: true, improved: true, extended: true }
})

const totalCount = computed(() =>
    (data.value.capped?.length || 0) +
    (data.value.improved?.length || 0) +
    (data.value.extended?.length || 0)
)

const groupOptions = computed(() => {
    const seen = new Map()
    for (const key of [ 'capped', 'improved', 'extended' ]) {
        for (const r of (data.value[key] || [])) {
            if (!seen.has(r.group_id)) seen.set(r.group_id, { id: r.group_id, name: r.group_name })
        }
    }
    return Array.from(seen.values()).sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: 'base' }))
})

function filterRows(rows) {
    const q = filters.search.trim().toLowerCase()
    const id = Number(filters.search.trim())
    const groupId = filters.group_id

    return rows.filter(r => {
        if (groupId !== 'all' && r.group_id !== groupId) return false
        if (!q) return true
        if (r.full_name && r.full_name.toLowerCase().includes(q)) return true
        if (r.club_name && r.club_name.toLowerCase().includes(q)) return true
        if (!Number.isNaN(id) && id > 0 && r.runner_id === id) return true
        return false
    })
}

const visibleSections = computed(() => {
    const defs = [
        { key: 'capped',   title: '📌 Categorii plafonate',    subtitle: 'Categorie superioară titlului curent — necesită confirmare la Minister.' },
        { key: 'improved', title: '⬆️ Categorii îmbunătățite', subtitle: 'Categorie nouă, mai bună decât pe ultima confirmare.' },
        { key: 'extended', title: '🔄 Categorii confirmate',   subtitle: 'Aceeași categorie, valabilitatea s-a extins.' }
    ]
    return defs
        .filter(s => filters.sections[s.key])
        .map(s => ({ ...s, rows: filterRows(data.value[s.key] || []) }))
})

function formatTime(seconds) {
    if (seconds == null) return '—'
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = seconds % 60
    return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0')
}

function resetFilters() {
    filters.search = ''
    filters.group_id = 'all'
    filters.sections = { capped: true, improved: true, extended: true }
}

onMounted(async () => {
    competitionId.value = window.location.pathname.split('/')[2]
    const res = await axios.get(`/competitions/${competitionId.value}/confirmations.json`)
    competition.value = res.data.competition || {}
    data.value = {
        capped:   res.data.capped   || [],
        improved: res.data.improved || [],
        extended: res.data.extended || []
    }
    loaded.value = true
})
</script>

<style scoped src="../shared/show.css"></style>
<style scoped src="../shared/index.css"></style>

<style scoped>
.section-card-title {
    display: flex;
    align-items: center;
    gap: 0.6rem;
}
.count-pill {
    background: #f1f5e8;
    color: #2d4a30;
    border-radius: 999px;
    padding: 0.1rem 0.7rem;
    font-size: 0.85rem;
    font-weight: 700;
}
.section-subtitle {
    color: #4f6b54;
    font-size: 0.9rem;
    margin: 0 0 0.7rem 0;
}
.footnote {
    color: #4f6b54;
    font-size: 0.82rem;
    font-style: italic;
    margin-top: 0.5rem;
}
.empty-row {
    color: #888;
    font-style: italic;
    text-align: center;
    padding: 1rem;
}
.empty-card {
    text-align: center;
    padding: 2rem;
    color: #4f6b54;
}
.empty-state-icon {
    font-size: 2rem;
    margin-bottom: 0.5rem;
}
</style>
