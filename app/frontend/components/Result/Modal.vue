<template>
    <div class="modal fade" tabindex="-1" id="editModal" aria-labelledby="editModalLabel" aria-hidden="true" ref="modalRef">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="editModalLabel">{{ isNew ? 'Crează Rezultat' : 'Editează Rezultatul'}}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form @submit.prevent>
                        <div class="mb-3">
                            <label for="runner" class="form-label">Sportiv</label>
                            <select id="runner_id" v-model="localResult.runner_id" class="form-control">
                                <option v-for="runner in filterData.runners" :key="runner.id" :value="runner.id">
                                    {{ runner.full_name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="club" class="form-label">Club</label>
                            <select id="club_id" v-model="localResult.club_id" class="form-control">
                                <option v-for="club in filterData.clubs" :key="club.id" :value="club.id">
                                    {{ club.club_name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="place" class="form-label">Locul</label>
                            <input type="number" class="form-control" id="place" v-model="localResult.place" />
                        </div>
                        <div class="mb-3">
                            <label for="time" class="form-label">Timpul</label>
                            <input type="time" step="1" class="form-control" id="time" v-model="localResult.time" />
                        </div>
                        <div class="mb-3">
                            <label for="date" class="form-label">Data</label>
                            <input type="date" class="form-control" id="date" v-model="localResult.date" />
                        </div>
                        <div class="mb-3">
                            <label for="category" class="form-label">Categoria Îndeplinită</label>
                            <select id="category_id" v-model="localResult.category_id" class="form-control">
                                <option v-for="category in filterData.categories" :key="category.id" :value="category.id">
                                    {{ category.category_name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="category" class="form-label">Îndeplinire</label>
                            <select id="status" v-model="localResult.status" class="form-control">
                                <option v-for="status in statusData" :key="status.id" :value="status.id">
                                    {{ status.name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="competition" class="form-label">Competiția</label>
                            <select id="competition_id" v-model="localResult.competition_id" class="form-control">
                                <option v-for="competition in filterData.competitions" :key="competition.id" :value="competition.id">
                                    {{ competition.competition_name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3" v-if="localResult.competition_id">
                            <label for="group" class="form-label">Grupa</label>
                            <select id="group_id" v-model="localResult.group_id" class="form-control">
                                <option v-for="group in competitionData.groups" :key="group.id" :value="group.id">
                                    {{ group.group_name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3" v-if="competitionData.wre">
                            <label for="wre_points" class="form-label">WRE Puncte</label>
                            <input type="number" class="form-control" id="wre_points" v-model="localResult.wre_points" />
                        </div>
                        <div class="mb-3" v-if="competitionData.ecn">
                            <label for="ecn_points" class="form-label">ECN Puncte</label>
                            <input type="number" class="form-control" id="ecnpoints" v-model="localResult.ecn_points" />
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
import axios from 'axios'

const props = defineProps({
    result: Object,
    isNew: Boolean
})

const emit = defineEmits(['save'])
const localResult = ref({ ...props.result })
const modalRef = ref(null)
let modalInstance = null
const filterData = ref({})
const competitionData = ref({})

const statusData = ref([{
        id: null,
        name: ""
    },
    {
        id: "confirmed",
        name: "Confirmat"
    },
    {
        id: "pending",
        name: "În așteptare"
    },
    {
        id: "unconfirmed",
        name: "Fără îndeplinire"
    }
])

watch(
    () => props.result,
    (newVal) => {
        localResult.value = { ...newVal }
    }
)

watch(
    () => localResult.value.competition_id,
    (newVal) => {
        if (!newVal) return
        getCompetitionData()
    }
)

onBeforeMount(() => {
    getFiltersData()
})

async function getFiltersData() {
    const res = await axios.get('/results/filters.json')
    filterData.value = res.data
}

function show() {
    if (!modalInstance) {
        modalInstance = new bootstrap.Modal(modalRef.value)
    }
    modalInstance.show()
}

function hide() {
    modalInstance.hide()
}

function handleSave() {
    if (!competitionData.value.wre) { localResult.value.wre_points = null }
    if (!competitionData.value.ecn) { localResult.value.ecn_points = null }
    localResult.value.time = timeToSeconds(localResult.value.time)
    emit('save', localResult.value, hide)
}

async function getCompetitionData() {
    const res = await axios.get(`/competitions/group_filters/${localResult.value.competition_id}.json`)
    competitionData.value = res.data
}

function timeToSeconds(time) {
  if (!time) return 0
  const [h, m, s] = time.split(':').map(Number)
  return h * 3600 + m * 60 + (s || 0)
}

defineExpose({ show, hide })
</script>
