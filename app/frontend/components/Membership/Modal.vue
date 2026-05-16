<template>
    <div class="modal fade" tabindex="-1" id="editModal" aria-labelledby="editModalLabel" aria-hidden="true" ref="modalRef">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="editModalLabel">{{ isNew ? 'Creaza Afilierea' : 'Editeaza Afilierea'}}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form @submit.prevent>
                        <div class="mb-3">
                            <label for="runner" class="form-label">Sportiv</label>
                            <select id="runner_id" v-model="localMembership.runner_id" class="form-control">
                                <option v-for="runner in filterData.runners" :key="runner.id" :value="runner.id">
                                    {{ runner.full_name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="club" class="form-label">Club</label>
                            <select id="club_id" v-model="localMembership.club_id" class="form-control">
                                <option v-for="club in filterData.clubs" :key="club.id" :value="club.id">
                                    {{ club.club_name }}
                                </option>
                            </select>
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
    membership: Object,
    isNew: Boolean
})

const emit = defineEmits(['save'])
const localMembership = ref({ ...props.membership })
const modalRef = ref(null)
let modalInstance = null
const filterData = ref({})

watch(
    () => props.membership,
    (newVal) => {
        localMembership.value = { ...newVal }
    }
)

onBeforeMount(() => {
    getFiltersData()
})

async function getFiltersData() {
    const res = await axios.get('/memberships/filters.json')
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
    emit('save', localMembership.value, hide)
}

defineExpose({ show, hide })
</script>
