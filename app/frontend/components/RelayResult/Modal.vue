<template>
    <div class="modal fade" tabindex="-1" id="relayEditModal" aria-labelledby="relayEditModalLabel" aria-hidden="true" ref="modalRef">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="relayEditModalLabel">{{ isNew ? 'Crează Ștafetă' : 'Editează Ștafetă' }}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form @submit.prevent>
                        <div class="mb-3">
                            <label for="competition" class="form-label">Competiția</label>
                            <select id="rr_competition_id" v-model="localRelay.competition_id" class="form-control">
                                <option v-for="competition in filterData.competitions" :key="competition.id" :value="competition.id">
                                    {{ competition.competition_name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3" v-if="localRelay.competition_id">
                            <label for="group" class="form-label">Grupa</label>
                            <select id="rr_group_id" v-model="localRelay.group_id" class="form-control">
                                <option v-for="group in competitionGroups" :key="group.id" :value="group.id">
                                    {{ group.group_name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="team" class="form-label">Echipa</label>
                            <input type="text" class="form-control" id="rr_team" v-model="localRelay.team" />
                        </div>
                        <div class="mb-3">
                            <label for="place" class="form-label">Locul</label>
                            <input type="number" class="form-control" id="rr_place" v-model.number="localRelay.place" />
                        </div>
                        <div class="mb-3">
                            <label for="time" class="form-label">Timpul total</label>
                            <input type="time" step="1" class="form-control" id="rr_time" v-model="localRelay.time_str" />
                        </div>
                        <div class="mb-3">
                            <label for="date" class="form-label">Data</label>
                            <input type="date" class="form-control" id="rr_date" v-model="localRelay.date" />
                        </div>
                        <div class="mb-3">
                            <label for="category" class="form-label">Categoria îndeplinită</label>
                            <select id="rr_category_id" v-model.number="localRelay.category_id" class="form-control">
                                <option v-for="category in filterData.categories" :key="category.id" :value="category.id">
                                    {{ category.category_name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="results_id" class="form-label">
                                ID-urile rezultatelor pe etape ({{ expectedLegCount || '?' }} valori, separate prin virgulă)
                            </label>
                            <input type="text" class="form-control" id="rr_results_id" v-model="localRelay.results_id_str"
                                placeholder="ex: 1023,1024,1025" />
                            <small class="form-text text-muted">
                                Ordinea contează — primul ID = etapa 1.
                            </small>
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

const localRelay = ref({})
const filterData = ref({ competitions: [], categories: [] })
const groupsByCompetition = ref({})
const modalRef = ref(null)
let modalInstance = null

const competitionGroups = computed(() => {
    return groupsByCompetition.value[localRelay.value.competition_id] || []
})

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

watch(() => props.relayResult, (val) => seedLocal(val), { immediate: true })

watch(() => localRelay.value.competition_id, async (newVal) => {
    if (!newVal) return
    if (groupsByCompetition.value[newVal]) return
    const res = await axios.get(`/competitions/${newVal}/group_filters.json`)
    groupsByCompetition.value[newVal] = res.data.groups || []
})

onBeforeMount(() => loadFilters())

async function loadFilters() {
    const res = await axios.get('/results/filters.json')
    filterData.value = {
        competitions: (res.data.competitions || []).map(c => ({ id: c.id, competition_name: c.competition_name, distance_type: c.distance_type })),
        categories:   res.data.categories || []
    }
}

function seedLocal(val) {
    const v = val || {}
    localRelay.value = {
        ...v,
        time_str:        secondsToTimeStr(v.time),
        results_id_str:  Array.isArray(v.results_id) ? v.results_id.join(',') : ''
    }
}

function show() {
    if (!modalInstance) {
        modalInstance = new bootstrap.Modal(modalRef.value)
    }
    modalInstance.show()
}

function hide() { modalInstance?.hide() }

function handleSave() {
    const payload = {
        id:           localRelay.value.id,
        place:        localRelay.value.place,
        team:         localRelay.value.team,
        time:         timeStrToSeconds(localRelay.value.time_str),
        date:         localRelay.value.date,
        category_id:  localRelay.value.category_id,
        group_id:     localRelay.value.group_id,
        results_id:   parseResultsIdStr(localRelay.value.results_id_str)
    }
    emit('save', payload, hide)
}

function parseResultsIdStr(str) {
    if (!str) return []
    return str.split(',').map(s => parseInt(s.trim(), 10)).filter(n => !isNaN(n))
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

defineExpose({ show, hide })
</script>
