<template>
    <div class="modal fade" tabindex="-1" id="relayEditModal" aria-labelledby="relayEditModalLabel" aria-hidden="true" ref="modalRef">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="relayEditModalLabel">{{ isNew ? 'Crează Ștafetă' : 'Editează Ștafetă' }}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form @submit.prevent>
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">Competiția</label>
                                <select v-model="localRelay.competition_id" class="form-control">
                                    <option v-for="competition in filterData.competitions" :key="competition.id" :value="competition.id">
                                        {{ competition.competition_name }}
                                    </option>
                                </select>
                            </div>
                            <div class="col-md-6" v-if="localRelay.competition_id">
                                <label class="form-label">Grupa</label>
                                <select v-model="localRelay.group_id" class="form-control">
                                    <option v-for="group in competitionGroups" :key="group.id" :value="group.id">
                                        {{ group.group_name }}
                                    </option>
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Echipa</label>
                                <input type="text" class="form-control" v-model="localRelay.team" />
                            </div>
                            <div class="col-md-2">
                                <label class="form-label">Locul</label>
                                <input type="number" class="form-control" v-model.number="localRelay.place" />
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Timpul total</label>
                                <input type="time" step="1" class="form-control" v-model="localRelay.time_str" />
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Data</label>
                                <input type="date" class="form-control" v-model="localRelay.date" />
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Categoria îndeplinită</label>
                                <select v-model.number="localRelay.category_id" class="form-control">
                                    <option v-for="category in filterData.categories" :key="category.id" :value="category.id">
                                        {{ category.category_name }}
                                    </option>
                                </select>
                            </div>
                        </div>

                        <hr />

                        <div class="leg-picker">
                            <div class="leg-picker-header">
                                <div class="leg-picker-title">
                                    Sportivi pe etape
                                    <span class="leg-counter" :class="legCounterClass">
                                        {{ selectedLegs.length }}<span v-if="expectedLegCount"> / {{ expectedLegCount }}</span>
                                    </span>
                                </div>
                                <small v-if="!localRelay.group_id" class="form-text text-muted">
                                    Selectează o grupă mai întâi.
                                </small>
                            </div>

                            <div v-if="localRelay.group_id" class="leg-picker-grid">
                                <div class="leg-pane">
                                    <div class="leg-pane-title">Disponibili</div>
                                    <div class="leg-pane-body">
                                        <div v-if="loadingLegs" class="leg-empty">Se încarcă…</div>
                                        <div v-else-if="availableLegs.length === 0" class="leg-empty">
                                            Niciun rezultat disponibil în această grupă.
                                        </div>
                                        <button
                                            v-for="leg in availableLegs"
                                            :key="leg.id"
                                            type="button"
                                            class="leg-row available"
                                            @click="addLeg(leg)">
                                            <span class="leg-name">{{ leg.full_name }}</span>
                                            <span class="leg-meta">{{ leg.club_name }}</span>
                                            <span class="leg-time">{{ formatTime(leg.time) }}</span>
                                        </button>
                                    </div>
                                </div>

                                <div class="leg-pane">
                                    <div class="leg-pane-title">Selectați (ordine etape)</div>
                                    <div class="leg-pane-body">
                                        <div v-if="selectedLegs.length === 0" class="leg-empty">
                                            Apasă pe un sportiv din stânga.
                                        </div>
                                        <div
                                            v-for="(leg, i) in selectedLegs"
                                            :key="leg.id"
                                            class="leg-row selected">
                                            <span class="leg-index">{{ i + 1 }}</span>
                                            <span class="leg-name">{{ leg.full_name }}</span>
                                            <span class="leg-meta">{{ leg.club_name }}</span>
                                            <span class="leg-time">{{ formatTime(leg.time) }}</span>
                                            <span class="leg-controls">
                                                <button type="button" class="btn btn-sm btn-light leg-arrow" :disabled="i === 0" @click="moveUp(i)" title="Sus">↑</button>
                                                <button type="button" class="btn btn-sm btn-light leg-arrow" :disabled="i === selectedLegs.length - 1" @click="moveDown(i)" title="Jos">↓</button>
                                                <button type="button" class="btn btn-sm btn-outline-danger leg-arrow" @click="removeLeg(i)" title="Șterge">✕</button>
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Inchide</button>
                    <button type="button" class="btn btn-primary" @click="handleSave">Salveaza</button>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, watch, onBeforeMount, computed } from 'vue'
import axios from '@/axios'

const props = defineProps({
    relayResult: { type: Object, default: () => ({}) },
    isNew: { type: Boolean, default: false }
})

const emit = defineEmits([ 'save' ])

const localRelay          = ref({})
const filterData          = ref({ competitions: [], categories: [] })
const groupsByCompetition = ref({})
const legsByGroupId       = ref({})           // group_id -> [{ id, full_name, club_name, time }]
const selectedLegs        = ref([])           // ordered array of leg objects
const loadingLegs         = ref(false)
const modalRef            = ref(null)
let modalInstance = null

const competitionGroups = computed(() => groupsByCompetition.value[localRelay.value.competition_id] || [])

const RELAY_LEG_COUNTS = {
    'Ștafetă clasică': 3,
    'Ștafetă sprint':  4
}

const expectedLegCount = computed(() => {
    const compId = localRelay.value.competition_id
    if (!compId) return null
    const comp = (filterData.value.competitions || []).find(c => c.id === compId)
    return RELAY_LEG_COUNTS[comp?.distance_type] || null
})

const legCounterClass = computed(() => {
    const n = selectedLegs.value.length
    if (!expectedLegCount.value) return ''
    if (n === expectedLegCount.value) return 'ok'
    if (n > expectedLegCount.value) return 'over'
    return 'under'
})

const selectedLegIds = computed(() => new Set(selectedLegs.value.map(l => l.id)))

const availableLegs = computed(() => {
    const all = legsByGroupId.value[localRelay.value.group_id] || []
    return all.filter(l => !selectedLegIds.value.has(l.id))
})

watch(() => props.relayResult, (val) => seedLocal(val), { immediate: true })

watch(() => localRelay.value.competition_id, async (newVal) => {
    if (!newVal || groupsByCompetition.value[newVal]) return
    const res = await axios.get(`/competitions/${newVal}/group_filters.json`)
    groupsByCompetition.value[newVal] = res.data.groups || []
})

watch(() => localRelay.value.group_id, async (newVal) => {
    if (!newVal) return
    await ensureGroupLegsLoaded(newVal)
    rehydrateSelectedFromResultsId()
}, { immediate: true })

onBeforeMount(() => loadFilters())

async function loadFilters() {
    const res = await axios.get('/results/filters.json')
    filterData.value = {
        competitions: (res.data.competitions || []).map(c => ({ id: c.id, competition_name: c.competition_name, distance_type: c.distance_type })),
        categories:   res.data.categories || []
    }
}

async function ensureGroupLegsLoaded(groupId) {
    if (legsByGroupId.value[groupId]) return
    loadingLegs.value = true
    try {
        const res = await axios.get('/results.json', {
            params: { group_data: groupId, "sorting[sort_by]": "place", "sorting[direction]": "asc" }
        })
        legsByGroupId.value[groupId] = (res.data || []).map(r => ({
            id:        r.id,
            full_name: r.full_name,
            club_name: r.club_name,
            time:      r.time
        }))
    } finally {
        loadingLegs.value = false
    }
}

function rehydrateSelectedFromResultsId() {
    const ids = Array.isArray(props.relayResult?.results_id) ? props.relayResult.results_id : []
    const pool = legsByGroupId.value[localRelay.value.group_id] || []
    selectedLegs.value = ids
        .map(id => pool.find(l => l.id === id))
        .filter(Boolean)
}

function seedLocal(val) {
    const v = val || {}
    localRelay.value = {
        ...v,
        time_str: secondsToTimeStr(v.time)
    }
    selectedLegs.value = [] // reset; rehydrated once group legs load
}

function addLeg(leg) {
    if (selectedLegIds.value.has(leg.id)) return
    selectedLegs.value.push(leg)
}

function removeLeg(i) {
    selectedLegs.value.splice(i, 1)
}

function moveUp(i) {
    if (i === 0) return
    const arr = selectedLegs.value
    ;[ arr[i - 1], arr[i] ] = [ arr[i], arr[i - 1] ]
}

function moveDown(i) {
    const arr = selectedLegs.value
    if (i === arr.length - 1) return
    ;[ arr[i + 1], arr[i] ] = [ arr[i], arr[i + 1] ]
}

function show() {
    if (!modalInstance) modalInstance = new bootstrap.Modal(modalRef.value)
    modalInstance.show()
}
function hide() { modalInstance?.hide() }

function handleSave() {
    const payload = {
        id:          localRelay.value.id,
        place:       localRelay.value.place,
        team:        localRelay.value.team,
        time:        timeStrToSeconds(localRelay.value.time_str),
        date:        localRelay.value.date,
        category_id: localRelay.value.category_id,
        group_id:    localRelay.value.group_id,
        results_id:  selectedLegs.value.map(l => l.id)
    }
    emit('save', payload, hide)
}

function timeStrToSeconds(str) {
    if (!str) return null
    const [ h, m, s ] = str.split(':').map(Number)
    return (h || 0) * 3600 + (m || 0) * 60 + (s || 0)
}

function secondsToTimeStr(seconds) {
    if (seconds == null) return ''
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = seconds % 60
    return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0')
}

function formatTime(seconds) {
    if (seconds == null) return '—'
    return secondsToTimeStr(seconds)
}

defineExpose({ show, hide })
</script>

<style scoped>
.leg-picker { margin-top: 0.5rem; }
.leg-picker-header { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 0.5rem; }
.leg-picker-title { font-weight: 600; color: #14532d; }
.leg-counter {
    margin-left: 0.5rem;
    padding: 1px 8px;
    border-radius: 999px;
    font-size: 0.85rem;
    font-weight: 700;
    background: #f1f5e8;
    color: #2d4a30;
}
.leg-counter.ok    { background: #dcfce7; color: #14532d; }
.leg-counter.over  { background: #fee2e2; color: #991b1b; }
.leg-counter.under { background: #fef3c7; color: #92400e; }

.leg-picker-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.75rem;
}
.leg-pane {
    background: #f8faf5;
    border: 1px solid #d6e4d8;
    border-radius: 10px;
    overflow: hidden;
}
.leg-pane-title {
    background: #f1f5e8;
    padding: 0.5rem 0.75rem;
    font-size: 0.78rem;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    font-weight: 700;
    color: #2d4a30;
    border-bottom: 1px solid #d6e4d8;
}
.leg-pane-body { max-height: 260px; overflow-y: auto; padding: 0.25rem; }

.leg-row {
    width: 100%;
    display: grid;
    grid-template-columns: auto 1fr 1fr auto auto;
    align-items: center;
    gap: 0.5rem;
    padding: 0.4rem 0.6rem;
    background: white;
    border: 1px solid #eef2eb;
    border-radius: 6px;
    margin-bottom: 4px;
    cursor: pointer;
    font-size: 0.9rem;
    text-align: left;
    transition: background 0.1s;
}
.leg-row:hover { background: #f1f5e8; }
.leg-row.selected { cursor: default; background: #ecfdf5; border-color: #bbf7d0; }
.leg-row.selected:hover { background: #ecfdf5; }
.leg-row.available { grid-template-columns: 1fr 1fr auto; }

.leg-name { font-weight: 600; color: #14532d; }
.leg-meta { color: #4f6b54; font-size: 0.82rem; }
.leg-time { font-variant-numeric: tabular-nums; color: #2d4a30; }
.leg-index {
    display: inline-flex;
    width: 22px; height: 22px;
    align-items: center; justify-content: center;
    background: #1f5f3a; color: white;
    border-radius: 999px;
    font-size: 0.78rem;
    font-weight: 700;
}
.leg-controls { display: inline-flex; gap: 2px; }
.leg-arrow { padding: 0 6px; font-size: 0.85rem; line-height: 1; min-width: 26px; }

.leg-empty { padding: 0.6rem; color: #888; font-style: italic; font-size: 0.85rem; text-align: center; }
</style>
