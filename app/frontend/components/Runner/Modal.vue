<template>
    <div class="modal fade" tabindex="-1" id="editModal" aria-labelledby="editModalLabel" aria-hidden="true" ref="modalRef">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="editModalLabel">{{ isNew ? 'Creaza Sportiv' : 'Editeaza Sportivul'}}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form @submit.prevent>
                        <div class="mb-3">
                            <label for="runner_name" class="form-label">Nume</label>
                            <input type="text" class="form-control" id="runner_name" v-model="localRunner.runner_name" />
                        </div>
                        <div class="mb-3">
                            <label for="surname" class="form-label">Prenume</label>
                            <input type="text" class="form-control" id="surname" v-model="localRunner.surname" />
                        </div>
                        <div class="mb-3">
                            <label for="gender" class="form-label">Genul</label>
                            <select id="gender" v-model="localRunner.gender" class="form-control">
                                <option v-for="gender in filterData.genders" :key="gender" :value="gender">
                                    {{ gender }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="best_category" class="form-label">Titlul Sportiv</label>
                            <select id="best_category_id" v-model="localRunner.best_category_id" class="form-control">
                                <option v-for="category in filterData.categories" :key="category.id" :value="category.id">
                                    {{ category.category_name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="yob" class="form-label">Anul Nașterii</label>
                            <input type="number" class="form-control" id="yob" v-model="localRunner.yob" />
                        </div>
                        <div class="mb-3">
                            <label for="license" class="form-label">Licență</label>
                            <input type="checkbox" class="custom-select" id="license" v-model="localRunner.license" />
                        </div>
                        <div class="mb-3">
                            <label for="club" class="form-label">Club</label>
                            <select id="club_id" v-model="localRunner.club_id" class="form-control">
                                <option v-for="club in filterData.clubs" :key="club.id" :value="club.id">
                                    {{ club.club_name }}
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="yob" class="form-label">WRE ID</label>
                            <input type="number" class="form-control" id="wre_id" v-model="localRunner.wre_id" />
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
    runner: Object,
    isNew: Boolean
})

const emit = defineEmits(['save'])
const localRunner = ref({ ...props.runner })
const modalRef = ref(null)
let modalInstance = null
const filterData = ref({})

watch(
    () => props.runner,
    (newVal) => {
        localRunner.value = { ...newVal }
    }
)

onBeforeMount(() => {
    getFiltersData()
})

async function getFiltersData() {
    const res = await axios.get('/runners/filters.json')
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
    emit('save', localRunner.value, hide)
}

defineExpose({ show, hide })
</script>
