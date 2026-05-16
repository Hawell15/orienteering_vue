<template>
    <div class="modal fade" tabindex="-1" id="editModal" aria-labelledby="editModalLabel" aria-hidden="true" ref="modalRef">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="editModalLabel">{{ isNew ? 'Creaza Competiție' : 'Editeaza Competiția'}}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form @submit.prevent>
                        <div class="mb-3">
                            <label for="competition_name" class="form-label">Nume</label>
                            <input type="text" class="form-control" id="competition_name" v-model="localCompetition.competition_name" />
                        </div>
                        <div class="mb-3">
                            <label for="country" class="form-label">Țara</label>
                            <input type="text" class="form-control" id="country" v-model="localCompetition.country" />
                        </div>
                        <div class="mb-3">
                            <label for="location" class="form-label">Localitatea</label>
                            <input type="text" class="form-control" id="location" v-model="localCompetition.location" />
                        </div>
                        <div class="mb-3">
                            <label for="date" class="form-label">Data</label>
                            <input type="date" class="form-control" id="date" v-model="localCompetition.date" />
                        </div>
                        <div class="mb-3">
                            <label for="distance_type" class="form-label">Tipul Distanței</label>
                            <select id="distance_type" v-model="localCompetition.distance_type" class="form-control">
                                <option v-for="distanceType in distanceTypes" :key="distanceType" :value="distanceType">
                                    {{ distanceType }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="wre_id" class="form-label">WRE ID</label>
                            <input type="number" class="form-control" id="wre_id" v-model="localCompetition.wre_id" />
                        </div>
                        <div class="mb-3">
                            <label for="ecn" class="form-label">ECN</label>
                            <input type="checkbox" class="custom-select" id="ecn" v-model="localCompetition.ecn" />
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
import { ref, watch, onMounted } from 'vue'
import axios from '@/axios'

const props = defineProps({
    competition: Object,
    isNew: Boolean
})

const distanceTypes = ref([])
const emit = defineEmits(['save'])
const localCompetition = ref({ ...props.competition })
const modalRef = ref(null)
let modalInstance = null

watch(
    () => props.competition,
    (newVal) => {
        localCompetition.value = { ...newVal }
    }
)

onMounted(() => {
    getDistanceTypesData()
})

async function getDistanceTypesData() {
    const res = await axios.get('/competitions/distance_types.json')
    distanceTypes.value = res.data
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
    emit('save', localCompetition.value, hide)
}

defineExpose({ show, hide })
</script>
