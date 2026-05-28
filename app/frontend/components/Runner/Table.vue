<template>
    <table class="forest-table">
        <thead>
            <tr>
                <th class="sortable" @click="orderTable('id')">FOS ID</th>
                <th class="sortable" @click="orderTable('full_name')">Nume</th>
                <th class="sortable" @click="orderTable('category_id')">Categoria actuală</th>
                <th class="sortable" @click="orderTable('category_valid')">Valabilitate</th>
                <th class="sortable" @click="orderTable('gender')">Genul</th>
                <th class="sortable" @click="orderTable('yob')">Anul nașterii</th>
                <th class="sortable" @click="orderTable('club_name')">Club</th>
                <th class="sortable" @click="orderTable('best_category_id')">Titlu sportiv</th>
                <th class="sortable" @click="orderTable('wre_id')">WRE</th>
                <th class="sortable" @click="orderTable('sprint_wre_place')">Sprint WRE</th>
                <th class="sortable" @click="orderTable('forest_wre_place')">Pădure WRE</th>
                <th>Acțiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td><a :href="`/runners/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`/runners/${element.id}`">{{ element.full_name }}</a></td>
                <td><a :href="`/categories/${element.category_id}`">{{ element.category_name }}</a></td>
                <td>{{ element.category_valid }}</td>
                <td>{{ element.gender }}</td>
                <td>{{ element.yob }}</td>
                <td><a :href="`/clubs/${element.club_id}`">{{ element.club_name }}</a></td>
                <td><a :href="`/categories/${element.best_category_id}`">{{ element.best_category_name }}</a></td>
                <td>
                    <span v-if="element.wre_id" class="cell-badge wre">#{{ element.wre_id }}</span>
                    <span v-else class="cell-no">—</span>
                </td>
                <td>
                    <span v-if="element.sprint_wre_place">{{ element.sprint_wre_place }}/{{ element.sprint_wre_rang }}</span>
                    <span v-else class="cell-no">—</span>
                </td>
                <td>
                    <span v-if="element.forest_wre_place">{{ element.forest_wre_place }}/{{ element.forest_wre_rang }}</span>
                    <span v-else class="cell-no">—</span>
                </td>
                <td>
                    <div class="row-actions">
                        <a class="row-action-btn show" :href="`/runners/${element.id}`">Arată</a>
                        <button v-if="isAdmin" class="row-action-btn edit" @click="editElement(element)">Editează</button>
                        <button v-if="isAdmin" class="row-action-btn delete" @click="deleteElement(element.id)">Șterge</button>
                    </div>
                </td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :runner="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
import { isAdmin } from '@/currentUser'
const props = defineProps({
    elements: Object
})

const emit = defineEmits(['order'])

const modalElement = ref({})
const modal = ref(null)

function deleteElement(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast sportiv?')) {
        axios.delete(`/runners/${id}`).then(() => {
            props.elements = props.elements.filter(runner => runner.id !== id)
        })
    }
}

function editElement(element) {
    modalElement.value = { ...element }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/runners/${elementData.id}.json`, { runner: elementData }).then(res => {
        const index = props.elements.findIndex(c => c.id === res.data.id)
        if (index !== -1) props.elements[index] = { ...props.elements[index], ...res.data }
        done()
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}
</script>

<style scoped src="../shared/index.css"></style>
