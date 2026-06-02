<template>
    <div class="index-page">
        <div class="index-hero">
            <div class="index-hero-inner">
                <div class="index-title-block">
                    <span class="index-eyebrow">🪪 Administrare</span>
                    <h1 class="index-title">Licențe sportivi</h1>
                </div>
                <span class="index-count">{{ data.length }}</span>
                <div class="search-box">
                    <input type="text" v-model="filters.search" placeholder="Caută după nume sau FOS ID…" class="search-input" />
                </div>
            </div>
        </div>

        <div class="filter-panel">
            <div class="filter-panel-head">
                <span class="filter-panel-title">⚙ Filtre</span>
                <button class="reset-btn" @click="resetFilters">Resetează</button>
            </div>
            <div class="filter-grid">
                <div class="filter-item">
                    <label class="label-filter">Licență</label>
                    <select v-model="filters.license" class="custom-select">
                        <option value="all">Toate</option>
                        <option value="true">Cu licență</option>
                        <option value="false">Fără licență</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Club</label>
                    <select v-model="filters.club" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="club in filterData.clubs" :key="club.id" :value="club.id">{{ club.club_name }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Genul</label>
                    <select v-model="filters.gender" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="g in filterData.genders" :key="g" :value="g">{{ g }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Anul nașterii</label>
                    <div class="range-wrapper">
                        <input type="number" v-model="filters['yob[from]']" min="0" class="custom-input" placeholder="De la" />
                        <span class="range-separator">—</span>
                        <input type="number" v-model="filters['yob[to]']" min="0" class="custom-input" placeholder="Până la" />
                    </div>
                </div>
            </div>
        </div>

        <div v-if="isAdmin" class="bulk-bar">
            <div class="bulk-bar-info">
                <span v-if="pendingCount" class="pending-pill">{{ pendingCount }} modificări nesalvate</span>
                <span v-else class="pending-pill quiet">Nicio modificare</span>
            </div>
            <div class="bulk-bar-actions">
                <button class="bulk-btn" :disabled="!visibleIds.length || allVisibleChecked" @click="setAllVisible(true)">Bifează toți (filtrați)</button>
                <button class="bulk-btn" :disabled="!visibleIds.length || noneVisibleChecked" @click="setAllVisible(false)">Debifează toți (filtrați)</button>
                <button class="bulk-btn ghost" :disabled="!pendingCount" @click="resetPending">Anulează modificările</button>
                <button class="bulk-btn primary" :disabled="!pendingCount || saving" @click="save">
                    {{ saving ? "Se salvează…" : "Salvează modificările" }}
                </button>
            </div>
        </div>

        <div class="table-card">
            <div class="table-scroll">
                <table class="forest-table">
                    <thead>
                        <tr>
                            <th style="width: 60px;">Licență</th>
                            <th style="width: 70px;">FOS ID</th>
                            <th>Sportiv</th>
                            <th>An</th>
                            <th>Club</th>
                            <th>Gen</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="r in data" :key="r.id" :class="{ pending: hasPending(r.id) }">
                            <td>
                                <input
                                    type="checkbox"
                                    class="license-checkbox"
                                    :disabled="!isAdmin"
                                    :checked="effectiveLicense(r)"
                                    @change="toggleLicense(r, $event.target.checked)" />
                            </td>
                            <td>{{ r.id }}</td>
                            <td><a :href="`/runners/${r.id}`">{{ r.full_name }}</a></td>
                            <td>{{ r.yob || '—' }}</td>
                            <td><a :href="`/clubs/${r.club_id}`">{{ r.club_name }}</a></td>
                            <td>{{ r.gender }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
            <div v-if="data.length === 0" class="empty-state">
                <div class="empty-state-icon">🔍</div>
                <div>Nu s-au găsit sportivi.</div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { reactive, ref, computed, onMounted, watch } from 'vue'
import axios from '@/axios'
import { isAdmin } from '@/currentUser'

const data       = ref([])
const filterData = ref({})
const pending    = reactive({})           // id -> desired license (bool)
const saving     = ref(false)

const DEFAULT_FILTERS = {
    "sorting[sort_by]":   "id",
    "sorting[direction]": "asc",
    "yob[from]":          "1000",
    "yob[to]":            "2100",
    "search":             "",
    "club":               "all",
    "license":            "all",
    "gender":             "all"
}

const filters = reactive({ ...DEFAULT_FILTERS })

const pendingCount = computed(() => Object.keys(pending).length)
const visibleIds = computed(() => data.value.map(r => r.id))
const allVisibleChecked = computed(() => data.value.every(r => effectiveLicense(r)))
const noneVisibleChecked = computed(() => data.value.every(r => !effectiveLicense(r)))

function hasPending(id) { return Object.prototype.hasOwnProperty.call(pending, id) }

function effectiveLicense(r) {
    return hasPending(r.id) ? pending[r.id] : !!r.license
}

function toggleLicense(r, newVal) {
    if (!!r.license === newVal) {
        delete pending[r.id]
    } else {
        pending[r.id] = newVal
    }
}

function setAllVisible(newVal) {
    data.value.forEach(r => toggleLicense(r, newVal))
}

function resetPending() {
    Object.keys(pending).forEach(k => delete pending[k])
}

async function save() {
    if (!pendingCount.value) return
    saving.value = true
    try {
        const runners = Object.entries(pending).map(([ id, license ]) => ({ id: Number(id), license }))
        await axios.patch('/runners/bulk_update_license.json', { runners })
        // reflect the saved state locally
        runners.forEach(({ id, license }) => {
            const row = data.value.find(r => r.id === id)
            if (row) row.license = license
        })
        resetPending()
    } finally {
        saving.value = false
    }
}

let debounceTimeout = null
watch(filters, () => {
    if (debounceTimeout) clearTimeout(debounceTimeout)
    debounceTimeout = setTimeout(() => getData(), 250)
}, { deep: true })

async function getData() {
    const cleanParams = {}
    Object.entries(filters).forEach(([ key, value ]) => {
        if (value === "all") return
        if (value === "false" || value === false) return
        if (value === "" || value === null) return
        cleanParams[key] = value
    })

    const res = await axios.get('/runners/license.json', { params: cleanParams })
    data.value = res.data

    const qs = new URLSearchParams(cleanParams).toString()
    window.history.replaceState({}, '', qs ? `${window.location.pathname}?${qs}` : window.location.pathname)
}

async function getFiltersData() {
    const res = await axios.get('/runners/filters.json')
    filterData.value = res.data
}

function resetFilters() {
    Object.assign(filters, DEFAULT_FILTERS)
    getData()
}

onMounted(() => {
    getFiltersData()
    const urlParams = new URLSearchParams(window.location.search)
    urlParams.forEach((value, key) => {
        if (key in filters) filters[key] = value
    })
    getData()
})
</script>

<style scoped src="../shared/index.css"></style>

<style scoped>
.bulk-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: white;
    border: 1px solid #d6e4d8;
    border-radius: 14px;
    padding: 0.6rem 0.9rem;
    margin: 0.6rem 0;
    flex-wrap: wrap;
    gap: 0.5rem;
}
.bulk-bar-info { display: flex; align-items: center; gap: 0.5rem; }
.bulk-bar-actions { display: flex; gap: 0.4rem; flex-wrap: wrap; }

.pending-pill {
    background: linear-gradient(135deg, #fef3c7, #fde68a);
    color: #92400e;
    border-radius: 999px;
    padding: 0.25rem 0.8rem;
    font-size: 0.85rem;
    font-weight: 700;
}
.pending-pill.quiet { background: #f1f5e8; color: #4f6b54; font-weight: 500; }

.bulk-btn {
    background: white;
    border: 1px solid #d6e4d8;
    color: #2d4a30;
    border-radius: 999px;
    padding: 0.35rem 0.9rem;
    font-size: 0.85rem;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.1s, border-color 0.1s, color 0.1s;
}
.bulk-btn:hover:not(:disabled) { background: #f1f5e8; border-color: #1f5f3a; }
.bulk-btn:disabled { opacity: 0.45; cursor: not-allowed; }
.bulk-btn.primary {
    background: linear-gradient(135deg, #1f5f3a, #2d7a4c);
    color: white;
    border-color: transparent;
    box-shadow: 0 4px 14px -4px rgba(20, 83, 45, 0.5);
}
.bulk-btn.primary:hover:not(:disabled) { background: linear-gradient(135deg, #14532d, #1f5f3a); }
.bulk-btn.ghost { background: transparent; color: #991b1b; border-color: #fecaca; }
.bulk-btn.ghost:hover:not(:disabled) { background: #fee2e2; }

.license-checkbox {
    width: 18px; height: 18px;
    cursor: pointer;
    accent-color: #1f5f3a;
}

tr.pending td {
    background-color: #fffbeb !important;
    box-shadow: inset 3px 0 0 #f59e0b;
}
</style>
