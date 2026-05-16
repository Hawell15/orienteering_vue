<template>
    <div class="modal fade" tabindex="-1" id="editModal" aria-labelledby="editModalLabel" aria-hidden="true" ref="modalRef">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="editModalLabel">{{ isNew ? 'Creaza Grupa' : 'Editeaza Grupa'}}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form @submit.prevent>
                        <div class="mb-3">
                            <label for="group_name" class="form-label">Nume</label>
                            <input type="text" class="form-control" id="group_name" v-model="localGroup.group_name" />
                        </div>
                        <div class="mb-3">
                            <label for="competition" class="form-label">Competiția</label>
                            <select id="competition_id" v-model="localGroup.competition_id" class="form-control">
                                <option v-for="competition in filterData.competitions" :key="competition.id" :value="competition.id">
                                    {{ competition.competition_display }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="clasa" class="form-label">Clasa</label>
                            <select id="clasa" v-model="localGroup.clasa" class="form-control">
                                <option v-for="clasa in filterData.clase" :key="clasa.id" :value="clasa.id">
                                    {{ clasa.category_name }}
                                </option>
                            </select>
                        </div>
                        <div v-if="isSelectedCompetitionEcn" class="mb-3">
                            <label for="ecn_coeficient" class="form-label">ECN Coeficient</label>
                            <input type="number" class="form-control" id="ecn_coeficient" v-model="localGroup.ecn_coeficient" />
                        </div>
                        <div class="mb-3">
                            <label for="rang" class="form-label">Rang</label>
                            <input type="number" class="form-control" id="rang" v-model="localGroup.rang" />
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
    group: Object,
    isNew: Boolean
})

const emit = defineEmits(['save'])
const localGroup = ref({ ...props.group })
const modalRef = ref(null)
let modalInstance = null
const filterData = ref({})

watch(
    () => props.group,
    (newVal) => {
        localGroup.value = { ...newVal }
    }
)

onBeforeMount(() => {
    getFiltersData()
})

async function getFiltersData() {
    const res = await axios.get('/groups/filters.json')
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
    emit('save', localGroup.value, hide)
}

const isSelectedCompetitionEcn = computed(() => {
    if (!filterData.value || Object.keys(filterData.value).length === 0) {
        return false
    }
    const comp = filterData.value.competitions.find(
        (c) => c.id === localGroup.value.competition_id
    )
    return comp?.ecn === true
})

defineExpose({ show, hide })
</script>
